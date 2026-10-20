-- One live World record per authored point. The host owns scope and geometry.
-- No per-point tasks: death cooldowns survive distance, disable and reparenting.
local Population = {}
Population.__index = Population

function Population.new(options)
    return setmetatable({ Options = options, Entries = {}, Serial = 0 }, Population)
end

function Population:Track(key)
    if self.Entries[key] then return end
    self.Serial += 1
    self.Entries[key] = { Key = key, Serial = self.Serial, RespawnAt = 0, RetryAt = 0 }
end

function Population:Reconcile(entry, now)
    local creature = entry.Creature
    if not creature or creature.Alive then return end
    if creature.RemovalReason == "Killed" then
        entry.RespawnAt = (creature.RemovedAt or now) + entry.RespawnSeconds
    end
    entry.Creature, entry.AwaySince, entry.WaitingSince = nil, nil, nil
end

function Population:Deactivate(key, now, reason)
    local entry = self.Entries[key]
    if not entry then return end
    self:Reconcile(entry, now)
    if entry.Creature then self.Options.Despawn(entry.Creature, reason or "SpawnInactive") end
    entry.Creature, entry.AwaySince, entry.WaitingSince = nil, nil, nil
end

function Population:Untrack(key, now)
    self:Deactivate(key, now, "SpawnRemoved")
    self.Entries[key] = nil
end

local function sameSpawn(a, b)
    return a and a.Kind == b.Kind and a.Level == b.Level and a.Scope == b.Scope
        and a.OwnerUserId == b.OwnerUserId and a.Frame == b.Frame
        and a.QuestId == b.QuestId and a.QuestSpawnId == b.QuestSpawnId
end

function Population:Step(now, players)
    local options, waiting = self.Options, {}
    local config = options.Config
    for key, entry in self.Entries do
        self:Reconcile(entry, now)
        local settings = options.Resolve(key)
        if not settings then
            self:Deactivate(key, now)
            entry.Settings = nil
            continue
        end
        if entry.Creature and not sameSpawn(entry.Settings, settings) then
            self:Deactivate(key, now, "SpawnReconfigured")
        end
        entry.Settings = settings
        local distance = options.DistanceSquared(settings, entry.Creature, players)
        if entry.Creature then
            if distance <= config.DeactivateDistance ^ 2 then
                entry.AwaySince = nil
            else
                entry.AwaySince = entry.AwaySince or now
                if now - entry.AwaySince >= config.DeactivateDelay
                    and options.CanDeactivate(entry.Creature, now) then
                    self:Deactivate(key, now)
                end
            end
        elseif distance <= config.ActivateDistance ^ 2 and now >= entry.RespawnAt and now >= entry.RetryAt then
            entry.WaitingSince = entry.WaitingSince or now
            table.insert(waiting, { Entry = entry, Distance = distance })
        else
            entry.WaitingSince = nil
        end
    end
    -- Older waiting points take precedence; a blocked point retries later instead
    -- of preventing the rest of the map from becoming populated.
    table.sort(waiting, function(a, b)
        if a.Entry.WaitingSince ~= b.Entry.WaitingSince then return a.Entry.WaitingSince < b.Entry.WaitingSince end
        if a.Distance ~= b.Distance then return a.Distance < b.Distance end
        return a.Entry.Serial < b.Entry.Serial
    end)
    for i = 1, math.min(#waiting, config.MaxSpawnsPerStep) do
        local entry = waiting[i].Entry
        entry.RetryAt = now + config.RetrySeconds
        local creature = options.Spawn(entry.Key, entry.Settings, players)
        if creature then
            entry.Creature = creature
            entry.RespawnSeconds = entry.Settings.RespawnSeconds
            entry.WaitingSince, entry.AwaySince = nil, nil
        end
    end
end

function Population:Destroy(now)
    for key in self.Entries do self:Untrack(key, now) end
end

return Population

# Creature world

## Optional encounters and soft positioning

`EncounterCoordinator.new({Target, Position, Contains?, Score?, Preparation?, ReviewInterval?, MinLock?, SwitchMargin?, DistanceScale?, PressureWeight?})` keeps participant membership, target assignments and pressure counts. `Target(record, participant)` returns a target handle; `Position(record, target)` returns a valid position or nil. Call `AddParticipant`, `Register(record, now)`, `GetTarget(record, now, committed)`, `RemoveParticipant`, `Remove(record)` and `Destroy()` from the authoritative host. Callbacks must not yield. `Score` adds a policy-specific cost; lower is better. No threat table, movement, pathfinding or wave lifecycle is owned here.

`Behaviour.Step` recognizes `record.Encounter` and `CombatReadyAt`. Encounter creatures bypass passive detection and spawn leash/reset, remain idle without a valid target and optionally delegate pursuit/cooldown spacing to `ops.Positioning(record, target, targetPosition, dt, now)`. The host validates movement against encounter bounds. Existing committed action movement is preserved. Ambient records retain the old behavior.

`CombatPositioning.new/Refresh/Delta` builds an encounter-local spatial snapshot and returns a bounded desired displacement. Definitions provide `Size`, optional `CombatRadius`, and the existing basic range/trigger/speed. Approach the nearest combat band directly; there is no persistent target angle. A body obstructing approach creates a temporary, persistent bypass side. Per-neighbor overlap correction preserves outward and tangential motion, reducing extra outward repair during lateral escape instead of damping the whole approach. This is local crowd steering, not navigation or physical collision resolution. The host must still sweep movements and check ground. Close the coordinator and discard pending state on every encounter teardown.

## Basic + Special behaviour

`Behaviour.Step` keeps `Behaviour.Attack` as the required basic attack for compatibility. `Behaviour.Special` is optional and uses the same attack fields plus `MinRange`. Basic wins inside its trigger range; a special is selected only outside that range, inside its own distance band, with visibility and its own cooldown ready. `Special.Approach=true` removes the upper activation distance for an already acquired target, while preserving the minimum distance and the movement cap (such as `Lunge.Distance`). Otherwise the creature pursues basic range.

Actions capture `AttackId` (`Basic` / `Special`) and `Attack` at start. Consumers must resolve damage, aiming and presentation from that action, not always from the species' basic. Only one action runs at a time. `NextAttack` and `NextSpecial` track independent cooldowns, starting after the corresponding recovery; special cooldown does not block melee pressure.

`Charge.StopDistance` optionally caps travel to the target distance minus this value, bounded by speed times active duration. `Charge.TrackDuringWindup=true` recalculates heading and travel throughout preparation, including the launch tick, then locks both for the entire dash. Without this flag, the initial aim remains fixed. `ChargeRemaining` drives movement and the announced endpoint. `ops.Action` is called again during aim updates with the same sequence/start; adapters must refresh presentation without resetting per-action state or replaying effects. Reaching the endpoint or hitting an obstacle starts recovery immediately; direction never homes after launch. Navigation, contact checks and cancellation remain injected server responsibilities.


`World.new({Parent, Definitions, Tag, Configure?, CanDamage?, Move?, Defeated?, Removed?})`

- Definitions map type IDs to `{Health, Size, MoveInterval?}` plus game-specific fields.
- `Spawn(typeId, groundFrame, context?)` returns a record. `context.Parent` optionally overrides the default parent.
- `Get(idOrPart)` resolves registered instances only.
- `Damage(record, amount, source)` returns a defeat snapshot on the first lethal hit, or `nil, reason` for invalid/refused hits. Nonlethal accepted hits return nil. Health is server-owned; attributes are output only.
- `Remove(record, reason?)` retires without a defeat. `Destroy()` removes all records.
- Call `Step(dt)` from one server scheduler; `Move(record, elapsed, time)` returns a new CFrame or nil. Movement updates are staggered and capped after long frames. This scheduler does not provide physics prediction or rollback.

`Configure(record)` sets game metadata before replication. `CanDamage(record, source)` enforces game permissions. `Defeated(record, source, snapshot)` fills game-specific fields or notifies progression; `Removed(record, reason)` handles cleanup. Registry retirement happens before callbacks. Callbacks should not yield; damage permission checks and cleanup must be synchronous. No automatic loot, player assumptions, AI, remotes, Humanoid or dependency on a particular game.

Markers are anchored BaseParts in Workspace. Native replication/streaming carries them. Consumers must not write their CFrame/health behind the runtime; gameplay state belongs in the record and the movement callback. Destroying a marker externally unregisters it without treating it as a kill.

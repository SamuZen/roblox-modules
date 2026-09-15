# Creature world

`World.new({Parent, Definitions, Tag, Configure?, CanDamage?, Move?, Defeated?, Removed?})`

- Definitions map type IDs to `{Health, Size, MoveInterval?}` plus game-specific fields.
- `Spawn(typeId, groundFrame, context?)` returns a record. `context.Parent` optionally overrides the default parent.
- `Get(idOrPart)` resolves registered instances only.
- `Damage(record, amount, source)` returns a defeat snapshot on the first lethal hit, or `nil, reason` for invalid/refused hits. Nonlethal accepted hits return nil. Health is server-owned; attributes are output only.
- `Remove(record, reason?)` retires without a defeat. `Destroy()` removes all records.
- Call `Step(dt)` from one server scheduler; `Move(record, elapsed, time)` returns a new CFrame or nil. Movement updates are staggered and capped after long frames. This scheduler does not provide physics prediction or rollback.

`Configure(record)` sets game metadata before replication. `CanDamage(record, source)` enforces game permissions. `Defeated(record, source, snapshot)` fills game-specific fields or notifies progression; `Removed(record, reason)` handles cleanup. Registry retirement happens before callbacks. Callbacks should not yield; damage permission checks and cleanup must be synchronous. No automatic loot, player assumptions, AI, remotes, Humanoid or dependency on a particular game.

Markers are anchored BaseParts in Workspace. Native replication/streaming carries them. Consumers must not write their CFrame/health behind the runtime; gameplay state belongs in the record and the movement callback. Destroying a marker externally unregisters it without treating it as a kill.

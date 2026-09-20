# Creature presentation

`ActionSnapshot.Encode(sequence, start, point?, attackId?)` accepts `Basic` or `Special` as the optional fourth argument. V2 appends one byte (0/1) to the 12/24-byte legacy payload. `Decode` accepts both formats and returns `sequence, start, point, attackId`; legacy payloads resolve to `Basic`. Unknown ids are rejected. Client consumers select the attack's timings/clip/shape and replace an existing telegraph when its attack definition changes. Both runtime and presentation must be deployed together; old decoders cannot read V2 payloads.


Use `Presentation.new({Tag, LocalTag?, Name?, TeleportDistance?, CreateVisual, Removed?})` on the client.
Markers are server-created BaseParts with `CreatureId`, `CreatureType`, `Health`, `MaxHealth`, and optional `MoveInterval` attributes. `CreateVisual(localRoot, marker)` returns a visual parented beneath the local root; attach its geometry to that root. It must be synchronous. `Removed(record)` may release extra resources; it must not award gameplay rewards.

The local root is invisible, anchored, non-colliding and excluded from spatial queries. It carries the creature identity and interpolated transform. Select it directly for targeting; keep rendered geometry optional. Never weld it to the replicated marker. Missing metadata defers creation. Leaving Workspace removes local state; reentry creates a fresh root at the current marker transform. `Destroy()` disconnects all listeners and removes all owned objects.

This is visual smoothing, not simulation prediction or historical hit validation. The game must keep local-only roots out of replayed gameplay callbacks. Server runtime lives in `Server/Creatures/World.lua`.

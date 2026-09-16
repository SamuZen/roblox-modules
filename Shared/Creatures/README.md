# Creature presentation

Use `Presentation.new({Tag, LocalTag?, Name?, TeleportDistance?, CreateVisual, Removed?})` on the client.
Markers are server-created BaseParts with `CreatureId`, `CreatureType`, `Health`, `MaxHealth`, and optional `MoveInterval` attributes. `CreateVisual(localRoot, marker)` returns a visual parented beneath the local root; attach its geometry to that root. It must be synchronous. `Removed(record)` may release extra resources; it must not award gameplay rewards.

The local root is invisible, anchored, non-colliding and excluded from spatial queries. It carries the creature identity and interpolated transform. Select it directly for targeting; keep rendered geometry optional. Never weld it to the replicated marker. Missing metadata defers creation. Leaving Workspace removes local state; reentry creates a fresh root at the current marker transform. `Destroy()` disconnects all listeners and removes all owned objects.

This is visual smoothing, not simulation prediction or historical hit validation. The game must keep local-only roots out of replayed gameplay callbacks. Server runtime lives in `Server/Creatures/World.lua`.

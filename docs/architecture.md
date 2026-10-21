# Simulation boundaries and extension contracts

## Current implementation

`ShipPhysics` owns the authoritative physical state. Only `_integrate_forces` applies thrust/torque and performs the explicitly requested debug reset. `FlightCommand` contains bounded local translation/rotation requests and main throttle. `PilotInput` is a replaceable adapter. `main.gd` samples it once per physics tick before the physics-server step; the body consumes the latest complete command. State observations have an integer `tick` and `state_sampled(tick)` signal. Signal observers must not mutate simulation state during integration. No render delta enters the flight integrator.

Crew uses a separate SubViewport/World3D as a local simulation space. No colliders are duplicated into the global flight simulation. Its CharacterBody, deck collisions and gravity are local. Rendering switches between the local viewport and actual ship cameras; this deliberately avoids moving-platform CharacterBody velocity artifacts. Ship identity is supplied by composition rather than an autoload. For a future Zero-G mode, replace only the local movement/inertial-force policy: local velocity and position remain explicit, artificial gravity can be zero, and a frame adapter can supply local effective acceleration and angular terms. An EVA crossing must explicitly convert pose and velocity, including ship linear velocity and omega cross offset; do not simply reparent the current CharacterBody.

`CrewStation.enter() -> bool`, `leave()`, `occupied` and `occupancy_changed(bool)` provide exclusive occupancy for this single-player prototype. Interaction rules (range, E) live in the composition layer, not in the station. Human/AI providers can later both emit `FlightCommand`. The station currently holds no network identity or authority rules. A later host must validate operator identity, station ownership and command limits itself.

Physics and input are separate modules; world/UI construction remains in one small composition script. Refactor geometry into scenes when assets or a second ship warrant it, rather than adding framework layers now.

## Planned contracts, deliberately not implemented

These describe integration boundaries, not shipped systems or empty scaffolding:

| Module | Inputs | Output / ownership |
|---|---|---|
| Sensors | host tick, sensor world pose, candidate physical states | timestamped contact observations with stable entity IDs; no direct weapon mutation |
| Missiles | validated station command, launcher pose/velocity, target/contact ID | host-owned physical entity, launch event; guidance consumes observations |
| Drones | operator intent, carrier frame and observations | bounded flight commands for their own body, deployment/recovery events |
| Damage | collision/hit event including tick, IDs, contact pose, impulse/energy | damage result event; explicit game-rule consumer changes component state |
| Replay events | validated commands, spawn/reset/station/damage events, tick IDs | ordered event log plus periodic full snapshots; rendering consumes playback state |

A future command envelope should contain `{tick, entity_id, station_id, operator_id, sequence, command}`. A host resolves one command per entity/tick with explicit stale/missing-input rules. Replay events should include `{tick, sequence, type, entity_id, payload}`; snapshots must include body pose, velocities, mass/configuration, station state and random generator state. Do not assume cross-machine floating-point physics is deterministic: record snapshots and correct playback as needed. Input polling or HUD text is not a replay source.

The future physiology consumer should receive local proper-acceleration vector, angular state and fixed dt, and integrate exposure by direction and duration. Today's exponential visual filter lives entirely in presentation and must not become a damage rule.

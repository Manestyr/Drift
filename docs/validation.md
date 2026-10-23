# Validation · Milestone 0.1

Executed in the cloud workspace on 2026-10-21 with **Godot 4.7.stable.official.5b4e0cb0f**, Linux x86_64, fixed physics tick 60 Hz. The official archive was SHA512-verified before use. `tools/bootstrap_godot.sh` was also executed successfully to verify the repeatable installation path.

Command: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.

- Headless editor import: exit 0, no parse/resource errors.
- Main scene headless run (120 process frames): exit 0, no runtime errors.
- Flight suite: **7 passed, 0 failed, 0 skipped**: linear coasting over 120 physics ticks, force/mass acceleration, proper acceleration telemetry, effective torque, world velocity invariance while turning, angular coasting, reset.
- Scene workflow suite: **10 passed, 0 failed, 0 skipped**: physical W binding, settling on deck, walking through bridge doorway, hull collision, entering pilot station/viewport switch, input-driven main thrust, exterior camera, station exit/first-person restoration, coasting after exit, local deck stability during global flight.
- `git diff --check`: passed before commit.

The physics tests wait for actual physics ticks. Force changes can take one server step to become visible in the body state; coast comparisons start after that transition, rather than falsely counting the final commanded impulse as damping.

**Not executed:** graphical desktop visual playtest, exported executable, tests on other desktop operating systems, network/replay tests (systems intentionally absent). Headless interaction tests invoke the same E/V action handler and sample action strengths, but do not establish mouse feel, final GPU appearance or keyboard delivery through a desktop window. Manually verify those using the first-flight steps in README.

Initial probing used preinstalled Godot 4.6.3. Final required validation uses the exact requested 4.7 version. Earlier test failures were corrected; none remain in the documented suites.

## Milestone 0.1.1 — Gamepad

Base: `32ab4ac`, implemented on `feature/milestone-0.1.1-gamepad`. Engine remains **Godot 4.7.stable.official.5b4e0cb0f**, Linux x86_64. Run the same `tools/check.sh`; it now includes `tests/gamepad_test.gd`.

- Headless editor import and 120-frame main-scene startup: successful, no parse/resource/runtime errors.
- Existing flight suite: **7 passed, 0 failed** (unchanged test file).
- Existing scene workflow: **10 passed, 0 failed** (unchanged test file).
- New controller suite: **63 passed, 0 failed**. Covers radial deadzone/boundary and configurable filtering, partial/diagonal analog scaling, all requested Input Map axes/buttons, drift-neutral outputs, sensitivity/inversion, mapped walking/look/seat/camera events, half-trigger physical acceleration, inertial coasting and world-velocity invariance during controller rotation, active-device/hint switching, disconnect fallback and settings persistence. It also tests real Godot focus navigation, D-pad adjustment, checkbox confirmation, menu reset, pause freezing simulation and menu-confirm isolation from station interaction.
- Total: **80 passed, 0 failed, 0 skipped**. The test runner preserves each command's exit status and stops on failure.
- `git diff --check`: successful. `ship_physics.gd`, `flight_command.gd` and both existing test files are unchanged from the base commit.

An initial boundary test exposed float precision at exactly 0.15. The filter now treats the boundary plus a 1e-6 tolerance as zero; the full suite passed after correction. No assertions were disabled.

**No physical Xbox/PlayStation controller was attached, and no graphical desktop playtest was possible.** Synthetic `InputEventJoypadMotion` / `InputEventJoypadButton` events test Godot's actual Input Map, input dispatch, GUI focus and physical simulation, not USB/Bluetooth connectivity, platform driver mappings, real trigger calibration, rendering or subjective handling. The README includes the remaining hardware checklist. Multiplayer/device isolation is not implemented.

## Milestone 0.1.2 — physical flight computer, 2026-10-22

Base: published `feature/gamepad-ready` / `c055a16`. Engine: **Godot 4.7.stable.official.5b4e0cb0f**, Linux x86_64, 60 Hz physics. Command: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.

- Headless editor import and 120-frame main-scene start: successful; no parse/resource/runtime errors in the final run.
- Original suites are unchanged: **7 flight + 10 workflow + 63 controller checks pass**.
- New suite: **58 passed, 0 failed**, including physical mouse torque/input routing, Ctrl modifier priority (also actual key events), all local brake axes, full braking in a moving reference frame, independent roll/rate braking, manual priority and actuator limits, neutral recovery after controller orbit, controller configuration persistence and GUI navigation, orbital camera/grid, and collision ray queries for clear launch corridor/solid wreck.
- **Total: 138 passed, 0 failed, 0 skipped.** New suite uses `--fixed-fps 60`: faster wall-clock execution with the same actual Godot 60-Hz physics integration and fixed dt, not a replacement mathematical integrator.
- Tests explicitly verify no immediate transform/velocity changes on command submission and bounded per-tick physical angular/linear velocity changes. Rotation preserves pre-existing linear world velocity; no physical state is teleported except test-fixture initialization and the explicit debug-reset path.

### Measured 180° rest-to-rest maneuvers

The test submits a 180° attitude target to the same bounded PD controller used by H/hold, from rest, independently about each principal axis. There is no UI auto-turn button. Reported times are **simulation seconds**, first entering both <2° attitude error and <2°/s angular speed, verified for at least 60 consecutive physics ticks and remaining settled through 12 simulated seconds.

| Axis | Actual Godot inertia (kg·m²) | Torque limit (N·m) | Settled time | Peak rate |
|---|---:|---:|---:|---:|
| Pitch X | 13,210,000 | 5,284,000 | 6.4667 s | 60.1632°/s |
| Yaw Y | 13,450,000 | 5,380,000 | 6.4667 s | 60.1632°/s |
| Roll Z | 740,000 | 296,000 | 6.4667 s | 60.1632°/s |

Maximum observed angular-velocity change per tick: **0.00666672 rad/s**, consistent with 0.4 rad/s² × 1/60 s. The ideal unlimited-switch bang-bang lower bound is `2 sqrt(pi / 0.4) = 5.605 s`; the PD settling result includes angular braking and is below ten seconds. The body retained its initial `(9, 3, -8) m/s` world velocity within 0.001 m/s throughout each maneuver. This result is not a claim about human mouse/controller performance.

Previous effective settings were 11,000,000 / 11,000,000 / 2,200,000 kg·m² and a common 1,800,000 N·m torque rating: maximum nominal acceleration 0.1636 / 0.1636 / 0.8182 rad/s², with an ideal pitch/yaw 180° lower bound of 8.76 s before additional controller settling. The new model follows the stated hull dimensions and gives matched responsiveness rather than disproportionately fast roll.

Initial development runs exposed a buffered synthetic-key event timing issue and a typed test-variable parse error; both were corrected before the final full run. No old tests/assertions were changed or disabled. `git diff --check` passes.

**No new graphical desktop or physical controller test was performed here.** The user reported successful desktop validation of the previous milestone; that is not validation of this version. Final visual contrast, arena scale/appearance, mouse feel, real gamepad mappings and frame rate remain desktop acceptance items. Collision geometry, control routing, controller menu choices and simulation behavior have headless coverage. No graphics performance benchmark or cross-platform export was run.

## Milestone 0.1.3 — functional cockpit, 2026-10-22

Base: `4843352` / `feature/milestone-0.1.2-flight-computer`. Godot **4.7.stable.official.5b4e0cb0f**, Linux x86_64.

- Headless import and 120-frame start: passed.
- All previous **138 checks** remain unchanged and pass.
- **33 new instrument checks** pass: snapshot coherence, world/local directions, independent acceleration direction, neutral thrust with persistent drift, actual manual RCS direction, automatic countersteer, reference velocity subtraction, N mapping/frame switching, observer non-mutation, updates to all three instruments, F3 visibility, mouse sensitivity scaling/persistence, viewport-texture links, and pilot-camera projection.
- Total: **171 passed, 0 failed, 0 skipped**. Runner: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.
- `ship_physics.gd`, `flight_computer.gd`, `flight_command.gd` and the four previous test files have no changes from the base. The existing maneuver measurements therefore remain applicable; the instrument UI never writes physical state.

### Actual rendering and readability check

An Xvfb display was made available using a Debian package verified by apt against signed official mirror metadata. Godot's real OpenGL Compatibility renderer ran with **Mesa 25.0.7 / llvmpipe (LLVM 19.1.7)** at **1280×720**. `tests/cockpit_capture.gd` captured startup, pilot manual counterthrust and automatic-braking frames; those images were inspected visually. See `docs/screenshots/bridge.png`, `cockpit.png`, `braking.png`. These are engine-rendered screenshots, not edited mockups. Audio used the Dummy driver on the final run. Xvfb reports an expected unsupported-VSync warning; this is not a rendering failure.

Headless projection explicitly sets a 1280×720 root window (the default headless dummy window otherwise reports 64×64). Actual projected corners:

| Instrument | Minimum pixel position | Maximum pixel position | Bounding size |
|---|---|---|---|
| Navigation | (78.79, 378.85) | (469.69, 693.79) | 390.90×314.95 |
| Propulsion | (470.41, 379.88) | (809.59, 673.18) | 339.18×293.31 |
| Computer | (810.31, 378.85) | (1201.21, 693.79) | 390.90×314.95 |

All four corners of every panel fit the unchanged pilot camera frustum. Texture resolution is 512×448 per screen. Main 24-pixel typography is approximately 16 screen pixels high on the center panel, slightly varying with perspective. The virtual rendered check verified front-face/texture orientation, all numeric values, frame placement and lack of a startup text wall. Initial rendering exposed an old sill occluding footers and navigation readouts drawn beneath the background; both were corrected before the final captures. A headless projection-fixture size issue and a typed test-variable parse error were also fixed, without weakening assertions.

**Not performed:** interactive human desktop playtest, physical Xbox/PlayStation input test, native GPU/frame-rate benchmark or other resolutions/platforms. This milestone has a real virtual-display visual check in addition to headless testing; it does not claim a new human hardware acceptance test. The screenshots' drift state is explicit capture-fixture setup, not production physics code.

## Milestone 0.1.4 — advanced dynamics, 2026-10-22

Base: completed, published **0acfdf7** / `feature/milestone-0.1.3-cockpit-instruments`; no unfinished intermediate branch was integrated. Engine remains **Godot 4.7.stable.official.5b4e0cb0f**, 60-Hz actual physics integration.

- Import and 120-frame headless main-scene start pass.
- All **171 previous checks pass without modifying their test files**.
- **57 new checks pass**: default/held/released drift, real C and controller chords, rebind persistence and stale-state clearing, all signed thrust forces/accelerations, main-plus-forward aggregate cap, shared asymmetric allocation/manual priority, neutral turn/coast invariance, no longitudinal drift correction, continuously updated local frame, bounded 90° maneuver, autonomous retrograde and settling, no automatic burn, low-speed inhibition before/during a maneuver, manual cancellation, relative-frame changes, roll continuity and cockpit snapshots. GUI button rebinding and overlapping-seat-button priority/fallback exit are covered.
- Total: **228 passed, 0 failed, 0 skipped**. Run `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.
- Production movement uses only fixed-tick forces/torques; pose/velocity writes are restricted to the pre-existing explicit reset. Maneuver test fixture initialization and screenshot fixtures are identified separately. No simulation-state write was added to instrument UI.

### 90° turn and commanded cross-drift cancellation

Initial world velocity `(0, 0, -40) m/s`, zero angular velocity, arena inertial frame. A repeatable test requests a 90° yaw attitude target through the existing PD controller. This is a measurement fixture, not a new automatic 90° UI command. **C is not active during the turn**. It reaches <0.5° error / <0.5°/s in **6.6833 simulated seconds**, retaining its original world velocity within 0.001 m/s.

Then held Drift Cancel and full manual main thrust are requested together. Initial local cross-drift **39.9985 m/s** falls below 0.05 m/s in **7.2500 s**, while the main engine accelerates along the new nose direction. Final local velocity: **(0.049181, 0, -144.8874) m/s**. Maximum physical per-tick velocity change **0.372681 m/s**, matching combined ~22.36 m/s² main/lateral acceleration at 60 Hz. The drift controller's local Z force remains exactly zero. Total staged turn plus drift removal is **13.9333 s**, not 7.25 s. No instantaneous velocity rotation, speed reset or teleport is used.

### Autonomous 180° retrograde

Initial world velocity `(0, 0, -30) m/s`, zero angular rate, arena frame. The test calls only the public retrograde request, without injecting an attitude target. Completion occurs after **7.9833 simulated seconds**: **0.32746°** forward-direction error, **0.13750°/s** angular speed. Peak angular speed **60.1632°/s**. Maximum per-tick angular-speed change **0.00666672 rad/s**, consistent with unchanged 0.4 rad/s² torque authority at 60 Hz.

Completion requires <0.5° target attitude error and <0.5°/s for 0.5 consecutive simulated seconds. Subsequent ticks continue the existing attitude-hold settling. World velocity remains unchanged within 0.001 m/s; main thrust and automatic translation force remain zero during and after completion. Tests additionally change the inertial reference while active and after completion: active targeting updates, but a finished maneuver does not silently restart. Near-zero speed and intentional manual rotation cancel safely.

### Rendering and remaining limitations

Three actual **1280×720** captures were rendered with Xvfb and Godot OpenGL Compatibility, **Mesa 25.0.7 / llvmpipe**, and inspected: `advanced-drift.png`, `advanced-retrograde.png`, `advanced-bindings.png`. They show held-drift status/ETA with main thrust, retrograde RCS activity without main thrust, and the controller binding menu. Audio used Dummy; Xvfb's unsupported-VSync warning is expected. These are renderer output from explicit fixtures, not image mockups or evidence of human piloting.

No interactive desktop/controller-hardware test, native-GPU performance measurement, fuel simulation or real thruster-layout verification was performed. The 50%/60% translation ratings are gameplay configuration. An initial typed test-local parse error was corrected; no tests were skipped or assertions disabled. Previous 0.1.2 maneuver figures use a looser settling criterion; the new retrograde completion time includes the stricter completion window, so it should not be compared as an unexplained physics regression.

## Milestone 0.2 — walkable crew ship and tactical stations, 2026-10-22

Base: completed published **f918df1** / `feature/milestone-0.1.4-advanced-flight`, verified against origin. New branch: `feature/milestone-0.2-crew-stations`. Engine: **4.7.stable.official.5b4e0cb0f**, fixed 60-Hz physics.

Final runner: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.

- Headless editor import: passed. Main-scene headless start, 120 process frames: passed.
- All six previous test suites are unchanged from f918df1: **228 checks passed**.
- `crew_stations_test.gd`: **67 checks passed**. Total **295 passed, 0 failed, 0 skipped**; runner exit 0, no script/runtime errors.
- New coverage: exclusive station identity/ownership, suitable harness/entry/exit, central multi-member roster including empty/partially secured cases, normal/combat aggregate force limits, zero force, direction preservation, actual rigid-body main-plus-lateral limit, persistent high velocity/coasting, applied telemetry, walking the whole bridge–corridor–engineering deck, both tactical cameras, keyboard and controller mappings/context conflicts, target cycling, controller harness/exit, relative velocity/basis, sensor cadence/range/acquisition/staleness, immediate tracking release, observation-only fire solution and permanently inhibited launch.
- At 120,000 kg, normal limit is **29.41995 m/s² / 3,530,394 N** resultant force. The secured requested combat limit is **78.4532 m/s² / 9,414,384 N**. Tests deliberately supply stronger hypothetical actuator ratings to exercise those limits; production ratings remain 2.4 MN main, 1.2 MN side/vertical/soft-forward and 1.44 MN reverse. Existing hardware's main acceleration remains **20 m/s²**, so normal operation does not artificially lose existing performance. Velocity initialized above 195 m/s remains above that value under the safety limit; neutral coasting and all station transitions preserve momentum to 0.001 m/s tolerance.
- Per-member load sampling is checked against an analytic case with seat orientation, alpha × r and omega × (omega × r). This is an observation interface, not a consciousness or health simulation.
- Review: `git diff --check` passed. FlightComputer/FlightCommand/PlayerInput are unchanged. The integrator still writes pose/velocities only in its pre-existing explicit debug-reset path; all flight motion uses forces and torques. Test-only initial state setup is labelled as such.

### Rendered checks and remaining acceptance work

Five final real renderer captures at **1280×720** were inspected: `crew-bridge.png`, `crew-sensors.png`, `crew-weapons.png`, `crew-pilot-safety.png`, `crew-engineering.png`. Godot OpenGL Compatibility ran on Xvfb with **Mesa 25.0.7 / llvmpipe (LLVM 19.1.7)** and Dummy audio. `tests/crew_capture.gd` reproduces these scripted camera/station fixtures on a graphical display; it deliberately refuses headless capture. Inspection verified physical screen frames/readability, correct texture orientation, observed/acquired versus insufficient contacts, simulated intercept with launch inhibition, readable HIGH-G DENIED status in pilot instruments, no startup debug wall, and the machinery aisle. A radar/text overlap and mirrored reverse-facing room signage were corrected before the final captures. The software driver's unsupported-VSync warning is expected.

**Not performed:** interactive human desktop playtest, physical Xbox/PlayStation hardware test, native-GPU performance benchmark, other resolutions or platform exports. No claim of real sensor fidelity: this is an omnidirectional range/quality/quantized observation model, without occlusion/signature physics. Only one present crew member is instantiated, although roster tests cover multiple members. The separate artificial-gravity interior still does not simulate acceleration falls, Zero-G or moving-deck inertial forces. Nominal crew-point load excludes collisions and artificial gravity. No multiplayer, AI, operational drones/missiles, health/blackout or damage simulation was added.

## Milestone 0.3 — FIRST CONTACT, 2026-10-22

Base: **1159aa0**, published `feature/milestone-0.2-crew-stations`, verified against origin before branching. New branch `feature/milestone-0.3-first-contact`. Engine remains **Godot 4.7.stable.official.5b4e0cb0f**, 60-Hz physics, Linux x86_64.

Runner: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`.

- Headless import, free-flight start and separate Kontakt Alpha start (120 process frames each): pass.
- All **295 previous checks pass, with all seven prior test files unchanged**.
- **69 combat checks**: sensor/safety/IFF launch denial, ammunition/cooldown, carrier velocity plus omega-cross-offset and actual solver-applied rack impulse, bounded thrust/side/rotation actuation, delta-v consumption, missing/stale guidance, zero-damping dry coast, actual unguided expiry without a hit, source guards against integration-time pose/velocity writes, enemy contact-dependent evasion, main/RCS/weapons/sensor failures, physical drone launch/movement/waypoints/hold/return/redeployment/empty-fuel coast, preserved stores, keyboard/controller station contexts, missile observer camera, structured selection events, actual supported/unsupported battles, latched result, controller focus and the real restart-button scene reload.
- Total **364 checks passed, 0 failed, 0 skipped**. `git diff --check` passes.

### Successful integrated example battle

This fixture starts the **real mission scene** and runs normal fixed-tick physics, AI, sensors, launchers and support adapters. It injects **no hit, damage, outcome, target pose or target velocity** during the battle. The player stays on foot without flight inputs, leaving both support stations unoccupied and enabled.

1. DRIFT starts at rest; ALPHA starts at `(120,35,-1100) m`, velocity `(-2,0,8) m/s`, facing toward the player. Normal sensor scans acquire and estimate the contact; enemy standoff/weave commands act through ShipPhysics.
2. Around **2.02 s**, BLUE-D1 deploys and physically moves to the carrier-relative guard waypoint `(-60,20,-80) m`, enabling its own sensor-gated point defense.
3. Friendly launches occur near **12.00, 26.02 and 40.03 s**. Opponent launches occur near **14.00 and 32.02 s**. Every launch consumes a rack round and applies the same missile physics/guidance rules.
4. Three actual friendly missile/hull collisions disable ALPHA. Two real defense-round/missile collisions intercept the opponent's attacks. Point defense consumes ammunition; no target-distance damage or timed kill shortcut is used.
5. **VICTORY at 43.85 simulated seconds**. Event counts: 1 drone_launch, 5 launch, 3 missile_hit, 3 system_damage, 2 intercept, 1 incapacitated. DRIFT's components remain 100%; ALPHA hull reaches 0. Outcome UI offers restart/free flight.

A second fixture disables **both** friendly support adapters and submits no manual fire/flight commands. Enemy physical missiles produce **DEFEAT at 54.5167 s**: 3 launches, 3 physical hits, 6 system-damage events, 1 incapacitated. DRIFT final hull 0, main 100, RCS 49, sensors 0, weapons 100. Actual range/sampling and propulsion functions respond to component state. A separate component test proves weapons can incapacitate a ship before hull destruction. These deterministic initial scenarios verify two outcomes; they do not guarantee every manual maneuver or every machine's physics timing gives identical results.

### Actual graphics and honest limits

Five **1280×720** screenshots were rendered and inspected using Xvfb, real Godot OpenGL Compatibility, **Mesa 25.0.7 / llvmpipe (LLVM 19.1.7)**, Dummy audio: `contact-weapons.png`, `contact-drone.png`, `contact-missile-flight.png`, `contact-victory.png`, `contact-mode-menu.png`. They show physically mounted distinct station screens, visible command hints, finite inventory/fuel, guided missile exterior flight, outcome controls and both modes accessible by menu focus. `tests/combat_capture.gd` runs the actual mission, suppresses rendering while advancing simulation between captures, then re-enables the real renderer; it does not fabricate image state or script hits. Driver's unsupported-VSync warning is expected.

Development checks caught default inherited damping on newly introduced bodies and pre-solver impulse/cache timing; final bodies use zero replacement damping and first-step physical impulse application, both tested. The new target-change test explicitly waits for the next sensor scan before selecting a newly launched contact, preserving the observation boundary rather than weakening it. All prior tests remain unchanged.

**Not performed:** interactive human desktop playtest, physical Xbox/PlayStation test, native GPU/frame-rate benchmark, cross-platform export. Known prototype limits: omnidirectional/no-occlusion sensors, optimistic seeker precision, idealized PD turret aiming, coarse component zones/contact-point fallback, simple AI and one drone type, no fuel mass loss or separate rotational-propellant accounting. An exhausted-ammo/out-of-range stalemate is possible and can be restarted through the mode menu; no forced winner is scripted. The inherited separate artificial-gravity interior is unchanged. No network implementation, cinematic replay player, campaign or crew health/blackout system was added.

## Milestone 0.3.1 — player agency and combat balance, 2026-10-22

Base: published **bf98faf** / `feature/milestone-0.3-first-contact`, verified against origin. New branch `feature/milestone-0.3.1-player-agency`. Engine **Godot 4.7.stable.official.5b4e0cb0f**, fixed 60-Hz physics.

- Headless import and starts of free flight and Kontakt Alpha: passed.
- Existing **364 checks pass**. The seven pre-0.3 test files are unchanged. The 69-check 0.3 combat suite retains every assertion: autonomous scenarios now explicitly select FULL AUTO/EASY/seed 1741; the role-consent fixture selects ASSISTED; lock/reaction fixtures wait for the explicit build/reaction period. The old rendered auto fixture similarly opts into FULL AUTO.
- **52 new checks pass**, total **416 passed, 0 failed, 0 skipped**. Runner: `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh`. Separate final import after adding optional legacy reproduction fixture also passes.
- New checks cover no friendly autonomous starts in MANUAL (including stale grant flags), no automatic drone deployment, live station handover and stale automatic launch rejection, actual console ownership, lock growth/improved quality/invalidation, controller single press/release and held-repeat suppression after reload, independent rack cooldowns, role grants/mode changes, real mission-menu configuration, measured acceleration estimates, physical ESCORT/DEFEND/HOLD/RECALL, inbound threat classification, bad-position range failure, changed battle results/protection from operator decisions, force-based pilot evasion without drone help, and complete repeated fixed-seed scenario equality.
- All runtime source changes preserve force/torque-driven motion. No ship force ratings, hull health, warhead damage or missile dynamics were increased for a faction/difficulty. Point defense uses the same observation-derived firing law on both sides. The tactical screen meshes moved 3 cm toward their camera and explicitly use linear filtering to remove a visible screen/bezel rendering artifact; local collision geometry is unchanged.

### Balance and actual visuals

Six old-code baseline battles were executed before changes. The final matrix executes **26 actual battles**: two seeds for every mode/difficulty pair plus eight command/position/maneuver comparisons. Raw data and complete explanation are in `docs/balance-0.3-baseline.json`, `docs/balance-0.3.1.json` and `docs/balance-0.3.1.md`. `tests/balance_report.gd` reproduces the matrix. This is a small reproducible sample, not a general population winrate.

MANUAL without commands: zero friendly launches/deployments; NORMAL loses after 41.43 s. An explicit approach/rack/guard operator schedule wins NORMAL in 24.15–24.27 s with 100% hull. Same attack schedule with no drone or a rear guard point ends with 66% hull. A lateral-force scenario with no drone receives zero missile hits but loses its own effective firing geometry, remaining ACTIVE at 120 s. Explicit FULL AUTO/NORMAL takes about 85.8 s and six launches; HARD also produces ACTIVE/stalemate cases at the 120-s horizon. No outcome is injected in these battles; the existing isolated restart UI fixture still clearly labels its synthetic finish call.

Six final **1280×720** captures were rendered through actual Godot OpenGL Compatibility on Xvfb, **Mesa 25.0.7 / llvmpipe (LLVM 19.1.7)**, Dummy audio, and inspected: `agency-mission-menu.png`, `agency-assisted-consent.png`, `agency-weapon-ready.png`, `agency-missile-ordered.png`, `agency-drone-escort.png`, `agency-drone-defend.png`. They show manual default, explicit consent, ownership/lock/READY, a PLAYER-origin missile, distinct drone orders and coverage/range. The optional capture script advances real simulation with rendering temporarily disabled between captures; it never fabricates hits/images. The driver's unsupported-VSync warning is expected.

Development checks exposed a freed typed-object lambda failure in long missile encounters, stale deferred sensor-delivery timing in defense lead, a test-local type inference issue and a target-acquisition fixture timing dependency. They were corrected and final tests retain the actual observation and authority gates. **No interactive human desktop/controller-hardware test, native GPU benchmark, export/platform test or broad statistical balance claim was performed.** Known limits remain idealized turret slew, omnidirectional/no-occlusion sensors, coarse hit zones, separate artificial-gravity interior and possible exhausted-ammunition/out-of-contact stalemates.

## Milestone 0.3.2 — flight diagnosis, PS UX and sound, 2026-10-23

Base **78e014c**, `feature/milestone-0.3.1-player-agency`; new branch `feature/milestone-0.3.2-flight-ps-sound`. All measurements use **Godot 4.7.stable.official.5b4e0cb0f**, fixed 60-Hz physics. The system's unrelated 4.6.3 executable was not used.

### Counterthrust investigation

The old code already clears `FlightCommand` each sample and derives held brakes from Input Map state. No ammunition-to-braking coupling exists. Baseline long-combat diagnosis observed main health **49%** after an actual engine-zone missile impact, with automatic force **(0,0,0)**. An isolated repeat through the authoritative `ComponentDamage.hit(Vector3(0,0,12))` path measures:

| Condition | Main request | Applied main | Automatic brake | Local net acceleration |
|---|---:|---:|---:|---:|
| Healthy, full R2 | 100% | 2,400,000 N | 0 N | Z = −20.0 m/s² |
| One main-zone hit, full R2 | 100% | 1,176,000 N | 0 N | Z = −9.8 m/s² |
| Healthy, deliberate R2 + L2 | 100% | 2,400,000 N | 0 N | Z = −8.0 m/s² (manual reverse = +1,440,000 N) |
| Released L2, R2 still full | 100% | 2,400,000 N | 0 N | Z = −20.0 m/s² |
| All translation/brake inputs released | 0% | 0 N | 0 N | 0 m/s²; velocity coasts |

Thus loss of engine power is a demonstrated explanation for the apparent missing ~1 g, not evidence of an actual opposing automatic force. **The exact user's hardware event could not be conclusively reproduced; persistent counterthrust after actual brake release was not reproduced.** A held tactical D-pad arm input could previously become a pilot brake when changing station before releasing it. This context carry-over is now explicitly blocked, as are held flight channels across pause/source handover and old pad state on replacement/disconnection. Neither physics ratings nor body state are changed as a workaround. The HUD now disambiguates health, actual main, brake RCS, manual reverse and net acceleration.

The new controller integration fixture physically fights **114.63 simulated seconds** (HARD, seed 1741). The operator deploys/orders a guard drone and sends deliberate R1 launches at approximately 14-s intervals; there is no automatic friendly firing grant. **Both sides expend all eight missiles** (`[0,0] / [0,0]`). The operator changes weapons → pilot after expenditure: healthy main receives request 1.0 and automatic force remains **(0,0,0)**. Damage/hits/results are not injected in this battle. A separate explicitly isolated engine-hit fixture restores its damage configuration before later input checks, without changing velocity or pose.

A separate mission-rule fixture starts with zero stores on both sides and one spawned unpowered physical missile at (500,500,500). At **52 s** the mission remains ACTIVE with zero automatic player force; it waits for the real missile's **55-s expiry** and a further **5-s ceasefire grace** before DRAW. It does not fake a missile impact or forced winner. One-sided exhaustion remains ACTIVE; explicit pause Disengage produces ABORTED and focused restart/free-flight controls.

### Tests and audio validation

Final Godot-4.7 headless import, 120-frame free-flight and Kontakt-Alpha starts, and all ten suites pass: **475 checks, 0 failed, 0 skipped** (416 prior assertions retained unchanged + 59 new checks). All 12 PCM file checks and the optional real-mixer recording test also pass. `git diff --check` is clean. Additional regressions cover PS/Xbox detection/manual schema/dynamic remap labels, full/partial/released controls, pause/station/device/disconnection state, controller-only tracking/racks/launch/drone ESCORT/DEFEND/HOLD/RECALL, live full ammunition expenditure, actual damage-derived force accounting, neutral coast, bounded audio pool/bus lifetime across three restarts, independent gains/mute/persistence, exterior structure suppression, paused cues, ordnance-aware exhaustion, draw and explicit abort. The normal runner uses fresh temporary user directories, per-process timeouts and fails on Godot script/runtime errors even with engine exit 0.

`tools/check_audio.py` validates all **12 actual shipped PCM files**: non-silent bounded RMS, peak <=0.801, initial attack, final release and engine loop seam <0.01. The files are original CC0 synthesis with reproducible generator, no imported third-party samples. A single Master limiter protects simultaneous voice summation; event cadence and player pools are bounded.

The optional **real AudioServer mixer** integration was run with Dummy audio, explicitly enabled in headless by `-- --audio-headless`. Its Ship-bus recording measured **peak 0.044677734375** during applied main thrust; after switching to exterior and allowing its fade, the Ship-bus recording measured **peak 0.0**. This proves signal generation/routing and vacuum suppression in the actual mixer; it is not a human listening test. Recordings are temporary `/tmp/drift032-ship.wav` and `/tmp/drift032-vacuum.wav`, not shipped assets. Normal fast headless CI checks event/state ownership without starting real-time playbacks; this also avoids an unfinished Godot playback-reference warning at immediate process shutdown.

### Actual graphics and limitations

Eight **1280×720** screenshots are generated by `tests/ps_sound_capture.gd` using actual OpenGL Compatibility rendering, Xvfb and Mesa/llvmpipe: `ps-weapons-blocked`, `ps-weapons-ready`, `ps-launch`, `ps-drone`, `ps-pilot`, `ps-pause`, `ps-audio-symbols`, `ps-disengage`. The fixture selects PS labels synthetically and issues explicit mission orders; images are not UI mockups. Software-renderer captures exposed intermittent missing glyph runs. Native Labels with per-display MSDF fonts, independent 2D canvases and bounded 10-Hz presentation improve the complete READY/blocked/drone screens, but the live post-launch capture still exhibits missing text fragments. This remains an open rendering issue, not a passed pixel-perfect graphical acceptance. The committed screenshots retain the actual output; they were not retouched. A real GPU/controller desktop check is the next recommended task. They are checked for legibility, active-schema command mapping, warnings, actual drone position/radius and focused controller menus. Unsupported V-Sync under the software renderer is expected.

**No physical PlayStation/Xbox controller, human desktop game session, human audio listening test, native GPU benchmark or platform export was available/performed.** Audio timbre/mix and trigger mapping still need hardware acceptance. Vibration is an acoustic cue; no haptic rumble was added. Structural spatialization is a simple local acoustic model without propagation/occlusion. Out-of-contact ships that still have offensive stores require deliberate disengagement, not an arbitrary timeout. Existing separate artificial-gravity interior, simplified hit zones, idealized defense turret and sensor limitations remain.

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

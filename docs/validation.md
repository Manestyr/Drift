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

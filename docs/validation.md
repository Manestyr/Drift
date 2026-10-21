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

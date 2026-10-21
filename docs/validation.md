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

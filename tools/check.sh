#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
test_root="$(mktemp -d /tmp/drift-check.XXXXXX)"
export XDG_DATA_HOME="$test_root/data"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_CACHE_HOME="$test_root/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
run_log="$test_root/engine.log"
trap 'rm -rf "$test_root"' EXIT
run_godot() {
 timeout 240 "$engine" "$@" 2>&1 | tee "$run_log"
 if rg -q 'SCRIPT ERROR:|^ERROR:|FAIL:' "$run_log"; then
  return 1
 fi
}
run_godot --version
run_godot --headless --path . --editor --import --quit
run_godot --headless --path . --quit-after 120
run_godot --headless --path . --script res://tests/flight_test.gd
run_godot --headless --path . --script res://tests/workflow_test.gd
run_godot --headless --path . --script res://tests/gamepad_test.gd
run_godot --headless --fixed-fps 60 --path . --script res://tests/flight_computer_test.gd
run_godot --headless --fixed-fps 60 --path . --script res://tests/instruments_test.gd
run_godot --headless --fixed-fps 60 --path . --script res://tests/advanced_flight_test.gd

run_godot --headless --fixed-fps 60 --path . --script res://tests/crew_stations_test.gd
run_godot --headless --fixed-fps 60 --path . res://scenes/contact_alpha.tscn --quit-after 120
run_godot --headless --fixed-fps 60 --path . --script res://tests/combat_test.gd

run_godot --headless --fixed-fps 60 --path . --script res://tests/agency_test.gd

run_godot --headless --fixed-fps 60 --path . --script res://tests/flight_ps_sound_test.gd
run_godot --headless --fixed-fps 60 --path . --script res://tests/tactical_combat_test.gd
python3 tools/check_audio.py

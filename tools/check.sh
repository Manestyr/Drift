#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/drift-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/drift-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/drift-cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
"$engine" --version
"$engine" --headless --path . --editor --import --quit
"$engine" --headless --path . --quit-after 120
"$engine" --headless --path . --script res://tests/flight_test.gd
"$engine" --headless --path . --script res://tests/workflow_test.gd
"$engine" --headless --path . --script res://tests/gamepad_test.gd
"$engine" --headless --fixed-fps 60 --path . --script res://tests/flight_computer_test.gd
"$engine" --headless --fixed-fps 60 --path . --script res://tests/instruments_test.gd
"$engine" --headless --fixed-fps 60 --path . --script res://tests/advanced_flight_test.gd

"$engine" --headless --fixed-fps 60 --path . --script res://tests/crew_stations_test.gd

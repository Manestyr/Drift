#!/usr/bin/env bash
# Official, pinned Linux x86_64 editor; installs outside the project checkout.
set -euo pipefail
install_dir="${DRIFT_GODOT_DIR:-/workspace/tools/godot-4.7}"
archive_name=Godot_v4.7-stable_linux.x86_64.zip
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
curl --fail --location --retry 2 "https://github.com/godotengine/godot/releases/download/4.7-stable/$archive_name" -o "$staging_dir/$archive_name"
# SHA512 published in the official 4.7-stable SHA512-SUMS.txt.
expected_sha=b639ca9c1ddea39bb3df89bd5283a51ca6047467abe6b25e9436566f2b2082ede633025073989ecf39c7d5d3c2493d80ea13e3af6dd5e261bbf89e462d6d2214
(cd "$staging_dir" && printf '%s  %s\n' "$expected_sha" "$archive_name" | sha512sum --check -)
mkdir -p "$install_dir"
unzip -o -q "$staging_dir/$archive_name" -d "$install_dir"
chmod +x "$install_dir/Godot_v4.7-stable_linux.x86_64"
"$install_dir/Godot_v4.7-stable_linux.x86_64" --version

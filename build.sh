#!/usr/bin/env bash
# Exports a standalone macOS .app into build/. Needs Godot 4.7 with the
# matching export templates installed.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
godot --headless --path . --export-release "macOS" build/ParrySurvivor.app
echo "-> build/ParrySurvivor.app"

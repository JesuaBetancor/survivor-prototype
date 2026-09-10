#!/usr/bin/env bash
# Runs the prototype from source. Needs Godot 4.7 on PATH.
set -euo pipefail
cd "$(dirname "$0")"
exec godot --path . "$@"

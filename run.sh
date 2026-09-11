#!/usr/bin/env bash
# Runs the prototype from source. Needs Godot 4.7 on PATH.
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"

# A fresh clone has no .godot/ (it is gitignored), so no global class cache
# exists yet and every `class_name` fails to resolve on the first launch. The
# editor builds that cache on import; do it here so cloning and running works
# without a mystery parse error.
if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
	echo "First run: importing project..."
	"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
fi

exec "$GODOT" --path . "$@"

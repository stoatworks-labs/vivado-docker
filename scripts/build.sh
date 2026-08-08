#!/usr/bin/env bash
# Run a Vivado batch Tcl flow inside the container against the mounted project.
# Usage:  scripts/build.sh [relative/path/in/workspace] [tcl-file]
# Default: run hw/create_project.tcl then hw/build.tcl for the atem-av-fw project.
set -euo pipefail
cd "$(dirname "$0")/.."

SUBDIR="${1:-hw}"
TCL="${2:-}"

if [[ -n "${TCL}" ]]; then
    exec docker compose run --rm vivado \
        bash -lc "cd /workspace/${SUBDIR} && vivado -mode batch -source ${TCL}"
fi

# Default two-step: create then build.
docker compose run --rm vivado bash -lc "\
    cd /workspace/${SUBDIR} && \
    vivado -mode batch -source create_project.tcl && \
    vivado -mode batch -source build.tcl"

#!/usr/bin/env bash
# Run a Vivado batch Tcl flow in the ALREADY-RUNNING persistent container (Unraid
# pattern). Bring the container up first:
#   docker compose -f docker-compose.yml -f docker-compose.unraid.yml up -d
#
# Usage:  scripts/exec-build.sh [subdir-in-workspace] [tcl-file]
# Default: hw/create_project.tcl then hw/build.tcl.
set -euo pipefail

CONTAINER="${CONTAINER:-vivado}"
SUBDIR="${1:-hw}"
TCL="${2:-}"

if [[ -n "${TCL}" ]]; then
    exec docker exec "${CONTAINER}" \
        bash -lc "cd /workspace/${SUBDIR} && vivado -mode batch -source ${TCL}"
fi

exec docker exec "${CONTAINER}" bash -lc "\
    cd /workspace/${SUBDIR} && \
    vivado -mode batch -source create_project.tcl && \
    vivado -mode batch -source build.tcl"

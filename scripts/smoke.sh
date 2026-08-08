#!/usr/bin/env bash
# Verify the Vivado install can synthesize for a part. Usage: scripts/smoke.sh [part]
set -euo pipefail
PART="${1:-xczu4cg-fbvb900-1-e}"
CONTAINER="${CONTAINER:-vivado}"
docker cp "$(dirname "$0")/../test" "$CONTAINER":/tmp/vdsmoke
docker exec "$CONTAINER" bash -lc \
  "vivado -mode batch -nojournal -nolog -source /tmp/vdsmoke/smoke.tcl -tclargs $PART 2>&1 | grep -iE 'SMOKE-OK|^ERROR:'"

#!/usr/bin/env bash
# Source Vivado's settings (from the mounted install volume) if present, then exec.
set -euo pipefail

# Find the newest installed Vivado settings64.sh under /opt/Xilinx.
settings="$(ls -d /opt/Xilinx/Vivado/*/settings64.sh 2>/dev/null | sort -V | tail -n1 || true)"
if [[ -n "${settings}" && -f "${settings}" ]]; then
    # shellcheck disable=SC1090
    source "${settings}"
else
    echo "[vivado-docker] note: no Vivado install found under /opt/Xilinx yet." >&2
    echo "[vivado-docker]       run 'run-installer.sh' first (see README)." >&2
fi

# License location (free ML Standard usually needs none; set if you have a .lic).
if [[ -n "${XILINXD_LICENSE_FILE:-}" ]]; then
    export XILINXD_LICENSE_FILE
fi

exec "$@"

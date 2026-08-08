#!/usr/bin/env bash
# Run AMD's Vivado installer (mounted at /installer) into /opt/Xilinx, headless.
#
# You provide the OFFLINE "Full Product Installation" installer — that installs
# without an AMD login (authentication happened at download). Do NOT use the small
# web-installer here; it would need account credentials inside the container.
#
# Layout expected (bind-mounted from the repo's ./installer):
#   /installer/xsetup                      (an already-extracted installer dir), OR
#   /installer/*.bin  /  /installer/*.tar.gz   (self-extracting / tarball — we extract)
#
# Config: /install/install_config.txt if present (see the template). If absent we
# fall back to interactive ConfigGen guidance, because module/EULA names change per
# Vivado version and a stale config silently installs the wrong thing.
set -euo pipefail

INSTALLER_DIR=/installer
DEST=/opt/Xilinx
CONFIG=/install/install_config.txt

echo "[run-installer] looking for an installer under ${INSTALLER_DIR} ..."

# Locate an xsetup: either already extracted, or extract a .bin/.tar.gz.
xsetup="$(find "${INSTALLER_DIR}" -maxdepth 3 -name xsetup -type f 2>/dev/null | head -n1 || true)"

if [[ -z "${xsetup}" ]]; then
    bin="$(find "${INSTALLER_DIR}" -maxdepth 1 -name '*.bin' | head -n1 || true)"
    tgz="$(find "${INSTALLER_DIR}" -maxdepth 1 \( -name '*.tar.gz' -o -name '*.tar' -o -name '*.tar.xz' \) | head -n1 || true)"
    workdir="${INSTALLER_DIR}/_extracted"
    mkdir -p "${workdir}"
    if [[ -n "${bin}" ]]; then
        echo "[run-installer] extracting self-extracting installer ${bin} ..."
        chmod +x "${bin}"
        "${bin}" --keep --noexec --target "${workdir}" || {
            echo "[run-installer] --keep/--noexec unsupported; running extractor directly"; "${bin}" --target "${workdir}" --noexec || true; }
    elif [[ -n "${tgz}" ]]; then
        echo "[run-installer] extracting ${tgz} ..."
        tar -xf "${tgz}" -C "${workdir}"
    else
        echo "[run-installer] ERROR: no xsetup, .bin or .tar.gz found in ${INSTALLER_DIR}" >&2
        echo "                Download the Vivado ML 'Full Product Installation' for Linux from AMD" >&2
        echo "                and place it in the repo's ./installer directory." >&2
        exit 1
    fi
    xsetup="$(find "${workdir}" -maxdepth 3 -name xsetup -type f | head -n1 || true)"
fi

[[ -n "${xsetup}" ]] || { echo "[run-installer] ERROR: could not locate xsetup after extraction" >&2; exit 1; }
srcdir="$(dirname "${xsetup}")"
echo "[run-installer] using installer at ${srcdir}"

if [[ ! -f "${CONFIG}" ]]; then
    cat >&2 <<EOF
[run-installer] No ${CONFIG} found.
    Module and EULA names differ per Vivado version, so generate a fresh config:
        cd "${srcdir}"
        ./xsetup -b ConfigGen        # pick 'Vivado ML Standard', save the config
    then copy it to the repo's install/install_config.txt and re-run this script.
    (A starting template is in install/install_config.template.txt.)
EOF
    exit 2
fi

echo "[run-installer] installing into ${DEST} (this takes a while) ..."
cd "${srcdir}"
# Long forms; flags are stable across recent unified installers. Batch = no GUI.
./xsetup \
    --agree XilinxEULA,3rdPartyEULA \
    --batch Install \
    --config "${CONFIG}" \
    --location "${DEST}"

echo "[run-installer] done. Verify with:  vivado -version"

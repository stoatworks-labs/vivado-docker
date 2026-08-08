# AGENTS.md — vivado-docker

## What this repo is
A Docker environment for running AMD/Xilinx Vivado headlessly on an x86-64 host. Prerequisites +
workflow only; no vendor binaries.

## Hard rules
- **Never commit Xilinx installers, binaries, bitstreams, or license files.** They are large,
  proprietary, and download-gated. `installer/`, `licenses/`, `*.bin`, `*.tar.gz`, `*.lic` and
  `install/install_config.txt` are gitignored — keep it that way.
- **No credentials in the image or repo.** Use the *offline* full installer so no AMD login is ever
  needed inside the container. Never add account tokens, passwords, or a hard-coded license server.
- **x86-64 only.** Vivado has no ARM build; the compose file pins `platform: linux/amd64`.

## Conventions
- Shell scripts are `bash`, `set -euo pipefail`, executable.
- Default branch `main`. In this fleet **commit means push**.
- If this repo is ever made **public**, add the fleet AI-assisted disclaimer to the README first
  (it's currently private).

## Related
- `atem-av-fw` (private) — the FPGA project this compiles; its `hw/` holds the Tcl this runs.
- Intended to be driven over SSH by an agent: keep every step non-interactive and log-friendly.

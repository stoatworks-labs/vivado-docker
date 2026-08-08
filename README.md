# vivado-docker

A reproducible **Docker build environment for AMD/Xilinx Vivado**, meant to be driven headlessly
(batch Tcl) on an x86-64 host — including over SSH by an agent. Built to compile the FPGA design in
[`atem-av-fw`](https://github.com/stoatworks-labs/atem-av-fw), but generic.

> **This repo contains no Vivado.** Vivado is ~100 GB, licensed, and download-gated behind an AMD
> account — it can't be baked into an image or redistributed. The image carries only the OS
> prerequisites and the workflow; **you** download AMD's installer and the container runs it into a
> persistent volume.

## Requirements
- An **x86-64** Docker host (Linux recommended). Vivado is x86-only — on Apple Silicon it would run
  under slow emulation, so use a real amd64 machine.
- **Docker + Docker Compose v2.**
- Disk: ~200 GB free (Vivado install ~100 GB + projects). RAM: 16 GB min, **32 GB recommended**.
- AMD's **"Vivado ML — Full Product Installation"** for Linux (the big offline installer). Use the
  *full offline* one, **not** the small web installer — the offline one installs without an AMD
  login, so no credentials ever enter the container.

## One-time setup
```bash
cp env.example .env          # then set UID/GID (id -u / id -g) and PROJECT_DIR
docker compose build         # build the prerequisite image
```

## Install Vivado (into a persistent volume)
1. Download AMD's **Full Product Installation** (`.bin` or `.tar.gz`) and drop it in `./installer/`.
2. Generate an install config for *your* version (module names change per release):
   ```bash
   docker compose run --rm vivado bash -lc \
     'd=$(find /installer -name xsetup -type f | head -1 | xargs dirname); cd "$d"; ./xsetup -b ConfigGen'
   ```
   Pick **Vivado ML Standard** (free). Copy the result to `install/install_config.txt`
   (a starting template is in `install/install_config.template.txt`).
3. Run the install (takes a while):
   ```bash
   docker compose run --rm vivado run-installer.sh
   ```
4. Verify:
   ```bash
   ./scripts/vivado-version.sh
   ```

The install lands in the named volume `xilinx_install` (mounted at `/opt/Xilinx`), so it survives
image rebuilds and never bloats a layer.

## Build a project
```bash
./scripts/build.sh                 # runs hw/create_project.tcl + hw/build.tcl in atem-av-fw
./scripts/build.sh hw synth.tcl    # or a specific Tcl in a subdir of /workspace
./scripts/shell.sh                 # interactive shell, Vivado on PATH
```
`/workspace` is your `PROJECT_DIR` (default `../atem-av-fw`), so the container builds the real repo
in place and reports land back on the host.

## Driving it remotely (over SSH)
The whole flow is non-interactive, so an agent or CI can drive it:
```bash
ssh you@host "cd vivado-docker && ./scripts/build.sh"
```
Long synth/impl runs should be backgrounded and polled rather than held open. See
[`atem-av-fw/hw/`](https://github.com/stoatworks-labs/atem-av-fw) for the Tcl this compiles and
`docs`/`STATUS.md` there for how the outputs (utilisation/timing) feed the design decisions.

## Running on Unraid
See [`docs/UNRAID.md`](docs/UNRAID.md) — it handles the two Unraid specifics (bind-mount the
100 GB install so it doesn't overflow `docker.img`, and run as a persistent `docker exec`-able
container) and covers both the CLI and Compose Manager routes.

## Notes
- **Free ML Standard** likely covers the target part (ZU4CG-class) and needs no license server; if
  you have a node-locked `.lic`, drop it in `./licenses/` and set `XILINXD_LICENSE_FILE` in `.env`.
- The image pins Ubuntu 22.04 and the `libtinfo5`/`libncurses5` compat libs that fix the common
  "Vivado won't start on 22.04" error.
- Do **not** commit installers, licenses, or `install_config.txt` — they're gitignored.

See [`AGENTS.md`](AGENTS.md) for conventions.

# Running vivado-docker on Unraid

Unraid is x86-64, so it's a valid Vivado host. Two Unraid-specific things are already handled by
this repo:

- **The ~100 GB install is a bind mount, not a Docker named volume** — a named volume would live in
  Unraid's fixed-size `docker.img` and overflow it. `XILINX_DIR` points at a real cache-pool path.
- **It runs as a persistent container** (`docker-compose.unraid.yml`) so it shows in the Docker tab
  and you `docker exec` builds into it, instead of a one-shot that Unraid shows as perpetually
  stopped.

## Before you start
- **Storage:** put everything on the **cache pool (SSD)**, not the spinning array — Vivado is very
  I/O heavy. You need ~200 GB free (install ~100 GB + projects).
- **RAM:** 16 GB minimum, **32 GB recommended**. A synth/impl run will use real memory and cores;
  don't do it while the server is busy.
- **Plugins:** the **Docker Compose Manager** plugin (Community Applications) is the tidy way; the
  CLI path below needs no plugin.

## Get the files onto the server
Unraid doesn't ship `git`. Easiest options:
- Copy the `vivado-docker` folder to the server over SMB (e.g. into `/mnt/user/appdata/vivado-docker`), **or**
- Install the **NerdTools** plugin for `git` and `git clone` it, **or**
- `git clone` it elsewhere and copy.

Also put the **atem-av-fw** checkout somewhere on the server (e.g. `/mnt/user/appdata/atem-av-fw`)
and the AMD **offline** Vivado installer into `vivado-docker/installer/`.

## Configure
Create `.env` next to `docker-compose.yml` (copy from `env.example`) with absolute cache paths:
```ini
UID=99            # Unraid's 'nobody'
GID=100           # Unraid's 'users'
PROJECT_DIR=/mnt/user/appdata/atem-av-fw
XILINX_DIR=/mnt/user/appdata/vivado/xilinx      # will hold the ~100GB install
XILINXD_LICENSE_FILE=                            # empty for free ML Standard
```
`mkdir -p /mnt/user/appdata/vivado/xilinx` first so the bind mount has a target.

## Path A — CLI (simplest)
SSH into Unraid, `cd` to the repo, then:
```bash
docker compose build
# generate the install config for your Vivado version:
docker compose run --rm vivado bash -lc \
  'd=$(find /installer -name xsetup -type f | head -1 | xargs dirname); cd "$d"; ./xsetup -b ConfigGen'
#   -> pick "Vivado ML Standard", copy result to install/install_config.txt
docker compose run --rm vivado run-installer.sh          # ~1hr, installs to XILINX_DIR
# bring up the persistent container:
docker compose -f docker-compose.yml -f docker-compose.unraid.yml up -d
docker exec -it vivado bash -lc "vivado -version"        # verify
./scripts/exec-build.sh                                   # build atem-av-fw/hw
```
The `vivado` container now appears in the Unraid **Docker** tab as running; stop/start it there.

## Path B — Docker Compose Manager (GUI)
1. **Apps** → install **Docker Compose Manager**.
2. **Docker** tab → **Add New Stack** → name it `vivado` → paste/point it at this repo's
   `docker-compose.yml` (add the `docker-compose.unraid.yml` override content for persistence), and
   set the same env values.
3. **Compose Up**. Do the installer step once via a console into the container (or the CLI above),
   then it stays up for exec-based builds.

## Driving it remotely (what Claude does)
```bash
ssh unraid "docker exec vivado bash -lc 'cd /workspace/hw && vivado -mode batch -source build.tcl'"
```
Long runs are backgrounded and polled, not held open.

## Alternative: an Unraid VM instead of a container
If you'd rather isolate it, an Unraid **KVM VM** (Ubuntu 22.04, 8 vCPU / 32 GB / 200 GB vdisk on
cache) running Vivado natively also works and keeps heavy synth off the Docker host. The container
route is lighter to stand up; the VM route isolates resources better. Either is fine.

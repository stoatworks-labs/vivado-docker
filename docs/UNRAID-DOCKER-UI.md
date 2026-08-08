# Adding vivado-docker via the Unraid Docker UI

The native **Docker → Add Container** template *uses an image* — it can't build a Dockerfile. So the
image is published to GHCR by CI (`.github/workflows/build-image.yml`) and the template just pulls
it. No CLI build needed. (If you'd rather build locally instead, see the bottom.)

Remember: this image has **no Vivado in it** — Vivado is installed once, at runtime, into a
bind-mounted folder. So the UI steps are: create the container → open its Console → run the
installer → thereafter exec/console for builds.

## 0. One-time: make the image pullable
After this repo's CI runs, an image exists at `ghcr.io/stoatworks-labs/vivado-docker:latest`.
Because the repo is private the package starts **private** — either:
- **Make the package public** (GitHub → your profile → Packages → `vivado-docker` → Package settings
  → Change visibility → Public). It's a generic Ubuntu+libs image, no secrets. Simplest, then Unraid
  pulls with no auth; **or**
- Keep it private and run once on Unraid: `docker login ghcr.io -u <you> -p <PAT-with-read:packages>`.

## 1. Prep host folders (on the cache pool / SSD)
Via the Unraid terminal or a share:
```
/mnt/user/appdata/vivado/xilinx      <- the ~100GB install lands here (create it)
/mnt/user/appdata/vivado/installer   <- put AMD's OFFLINE Vivado installer here
/mnt/user/appdata/vivado/licenses    <- optional .lic
/mnt/user/appdata/atem-av-fw         <- the project checkout (mounted as /workspace)
```
Put AMD's **"Vivado ML — Full Product Installation" (Linux)** into the `installer` folder.

## 2. Docker → Add Container
Toggle **Advanced View** (top-right) so all fields show, then set:

| Field | Value |
|---|---|
| **Name** | `vivado` |
| **Repository** | `ghcr.io/stoatworks-labs/vivado-docker:latest` |
| **Network Type** | `Bridge` (nothing is served; `None` is fine too) |
| **Console shell command** | `bash` |
| **Extra Parameters** | `--shm-size=2g` |
| **Post Arguments** | `sleep infinity` |

`Post Arguments = sleep infinity` is what keeps this batch tool **running** so Unraid shows it green
and you can exec into it.

### Add these Paths (click **Add another Path**)
| Container path | Host path | Access |
|---|---|---|
| `/opt/Xilinx` | `/mnt/user/appdata/vivado/xilinx` | Read/Write |
| `/installer` | `/mnt/user/appdata/vivado/installer` | Read/Write |
| `/licenses` | `/mnt/user/appdata/vivado/licenses` | Read/Write |
| `/workspace` | `/mnt/user/appdata/atem-av-fw` | Read/Write |

### Add this Variable (optional)
| Name | Key | Value |
|---|---|---|
| License file | `XILINXD_LICENSE_FILE` | *(empty for free ML Standard, or `/licenses/Xilinx.lic`)* |

Click **Apply**. Unraid pulls the image and starts the container; it should show **started**.

## 3. Install Vivado (once) via the container Console
Click the `vivado` container icon → **Console**. Then:
```bash
# generate the install config for your Vivado version:
d=$(find /installer -name xsetup -type f | head -1 | xargs dirname); cd "$d"
./xsetup -b ConfigGen         # choose "Vivado ML Standard"; note where it saved the config
cp <that-config> /installer/install_config.txt
# run the headless install (~1 hour) into /opt/Xilinx:
run-installer.sh
vivado -version               # verify
```
(`run-installer.sh` reads `/installer/install_config.txt`, which is why you copy it there.)

## 4. Run builds
From the container **Console**:
```bash
cd /workspace/hw && vivado -mode batch -source build.tcl
```
Or from the Unraid terminal / over SSH:
```bash
docker exec vivado bash -lc "cd /workspace/hw && vivado -mode batch -source build.tcl"
```
That `docker exec` form is exactly how Claude drives it once you share SSH to the box.

## Prefer to build the image locally instead of GHCR?
Skip step 0, get the repo folder onto the server, and once via the Unraid terminal:
```bash
docker build --build-arg UID=99 --build-arg GID=100 -t vivado-docker:latest /path/to/vivado-docker
```
Then in step 2 set **Repository** to `vivado-docker:latest` (local image) and **don't** force-update
it (there's no registry to pull from).

## Notes
- Keep everything on the **cache pool**; a synth run is I/O and RAM heavy (32 GB recommended).
- Stop/start/autostart the container from the Docker tab like any other.
- The container runs as `nobody:users` (99:100) so files under appdata stay correctly owned.

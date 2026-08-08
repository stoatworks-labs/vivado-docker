# Unraid user template

`my-vivado.xml` pre-fills the Unraid **Add Container** form with the correct image, the persistent
`sleep infinity` command, `--shm-size=2g`, and the four bind mounts — so you don't hand-enter fields
(and hit typos or trailing spaces).

## Install the template
Put the file on the server at:
```
/boot/config/plugins/dockerMan/templates-user/my-vivado.xml
```
Get it there any way that's easy — SMB to the `flash` share (`/boot/...`), or on the Unraid terminal:
```bash
mkdir -p /boot/config/plugins/dockerMan/templates-user
curl -fsSL -o /boot/config/plugins/dockerMan/templates-user/my-vivado.xml \
  https://raw.githubusercontent.com/stoatworks-labs/vivado-docker/main/unraid/my-vivado.xml
```

## Use it
1. **Docker** tab → **Add Container** → in the **Template** dropdown pick **my-vivado** (under
   "User templates"). All fields populate.
2. First create the host folders (cache pool):
   `/mnt/user/appdata/vivado/{xilinx,installer,licenses}` and your `atem-av-fw` checkout. Drop AMD's
   **offline** Vivado installer into `.../vivado/installer`.
3. **Apply.** It pulls `ghcr.io/stoatworks-labs/vivado-docker:latest` and starts (shows green
   because of `sleep infinity`).
4. Install Vivado once and build — see [`../docs/UNRAID-DOCKER-UI.md`](../docs/UNRAID-DOCKER-UI.md)
   steps 3–4.

## Notes
- The **package must be public** (or `docker login ghcr.io` on the host) or the pull returns
  `unauthorized`. Making the *repo* public does not make the *package* public — flip it on the
  package's own settings page.
- **Do not enable the Tailscale option** on this container — it overrides the image entrypoint. If
  you need remote access, reach the box's SSH and `docker exec` instead.
- Runs as `nobody:users` (99:100) so appdata files stay correctly owned.

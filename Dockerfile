# Vivado build environment — prerequisites only, NO Vivado inside.
# The AMD/Xilinx installer is run at runtime into a mounted volume (see README).
#
# Ubuntu 22.04 is AMD's best-supported Linux for recent Vivado releases.
FROM --platform=linux/amd64 ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
# Match these to your host user so mounted files aren't root-owned.
ARG UID=1000
ARG GID=1000

# Vivado + its installer need these on 22.04. libtinfo5/libncurses5 are the classic
# "Vivado won't launch on Ubuntu 22.04" fix (the tools link libtinfo.so.5). The X
# libs are needed even for batch mode because the binaries link them; xvfb gives a
# virtual display for any step that insists on one. build-essential is required by
# the HLS flow that re-synthesizes reconfigured video IP (v_mix, v_proc_ss) — without
# it those fail with "'assert.h' file not found".
RUN apt-get update && apt-get install -y --no-install-recommends \
        libtinfo5 libncurses5 libncursesw5 \
        libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxrandr2 \
        libxfixes3 libxft2 libfontconfig1 libfreetype6 libgtk2.0-0 \
        libstdc++6 libc6 \
        build-essential \
        xvfb x11-apps \
        locales ca-certificates \
        tar unzip xz-utils libarchive-tools procps net-tools wget \
        graphviz \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Non-root user matching the host uid/gid.
RUN groupadd -g ${GID} builder 2>/dev/null || true \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash builder 2>/dev/null || true \
    && mkdir -p /opt/Xilinx /installer /workspace /licenses \
    && chown -R ${UID}:${GID} /opt/Xilinx /installer /workspace /licenses

COPY --chmod=0755 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=0755 install/run-installer.sh /usr/local/bin/run-installer.sh
# Put Vivado on PATH for login shells too, so `docker exec <c> bash -lc "vivado …"`
# works (exec bypasses the entrypoint) — used by the persistent Unraid pattern.
COPY scripts/profile-vivado.sh /etc/profile.d/zz-vivado.sh

USER builder
WORKDIR /workspace

# The entrypoint sources Vivado's settings64.sh (from the mounted /opt/Xilinx) if
# present, then execs whatever command you pass.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]

# /etc/profile.d/zz-vivado.sh — put Vivado on PATH for login shells.
# Lets `docker exec <c> bash -lc "vivado ..."` work (exec bypasses the entrypoint).
# Guarded so it is silent when Vivado is not installed yet.
# 2025.2+ layout is /opt/Xilinx/<ver>/Vivado/settings64.sh; older is /opt/Xilinx/Vivado/<ver>/.
__vivado_settings="$(ls -d /opt/Xilinx/*/Vivado/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh 2>/dev/null | sort -V | tail -n1)"
if [ -n "${__vivado_settings}" ] && [ -f "${__vivado_settings}" ]; then
    . "${__vivado_settings}"
fi
unset __vivado_settings

# /etc/profile.d/zz-vivado.sh — put Vivado on PATH for login shells.
# Lets `docker exec <c> bash -lc "vivado ..."` work (exec bypasses the entrypoint).
# Guarded so it is silent when Vivado is not installed yet.
__vivado_settings="$(ls -d /opt/Xilinx/Vivado/*/settings64.sh 2>/dev/null | sort -V | tail -n1)"
if [ -n "${__vivado_settings}" ] && [ -f "${__vivado_settings}" ]; then
    . "${__vivado_settings}"
fi
unset __vivado_settings

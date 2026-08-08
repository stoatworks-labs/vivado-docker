# Out-of-context synthesis smoke test. Usage:
#   vivado -mode batch -source smoke.tcl -tclargs <part>
set part [lindex $argv 0]
if {$part eq ""} { set part xczu4cg-fbvb900-1-e }
create_project -in_memory -part $part
read_verilog [file join [file dirname [info script]] smoke.v]
synth_design -top smoke -mode out_of_context -part $part
puts "SMOKE-OK synthesized for $part"
report_utilization

project_new alu_benchmark -overwrite
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY alu_wrapper
set_global_assignment -name VERILOG_FILE rtl/alu_wrapper.v
set_global_assignment -name VERILOG_FILE rtl/alu_reducepower/biriscv_alu_adaptive.v
set_global_assignment -name SDC_FILE alu_timing.sdc
project_close

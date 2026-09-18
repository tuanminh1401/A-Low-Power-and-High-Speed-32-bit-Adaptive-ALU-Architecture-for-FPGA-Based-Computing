project_new alu_goc_benchmark -overwrite
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY alu_goc_wrapper
set_global_assignment -name VERILOG_FILE rtl/alu_goc_wrapper.v
set_global_assignment -name VERILOG_FILE rtl/alu_goc/biriscv_alu_standalone.v
set_global_assignment -name SDC_FILE alu_timing.sdc
project_close

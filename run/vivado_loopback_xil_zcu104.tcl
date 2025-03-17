put "To be run from run/work"

set PROJECT_NAME loopback_xil_zcu104
# set RTL_DIR      ../rtl
# set CONFIG_DIR   .

set MM2S_W 128
set S2MM_W 128
set FREQ   250

source ../../tcl/boards/zcu104.tcl
source ../../tcl/vivado_xil_ip.tcl
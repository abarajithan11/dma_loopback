# Basic DMA Loopback with two AXI DMAs (RTL) and C firmware

This repository contains a simple example of a DMA loopback design using two AXI DMAs. 
The design is implemented in SystemVerilog RTL and the software is written in C.
We simulate the RTL and C firmware together using either Verilator or Vivado Xsim.
Waveforms from simulation are generated as `run\build\top_tb.vcd` or an `wdb` file.

### Simulate in Verilator (Linux)

Add Verilator path (eg. `/tools/verilator/bin`) to `$PATH`
```
make veri
```

### Simulate in Vivado Xsim (Linux)

Add Vivado path (eg. `/tools/Xilinx/Vivado/2022.2/bin`) to `$PATH`
```
make xsim
```

### Simulate in Windows with Vivado

First update `XIL_PATH` in `run/xsim.bat`, then run these in powershell
```
cd run
./xsim.bat
```

## Extending the design

### Adding more DMAs:

- Update `rtl\dma_controller.sv` with more registers and logic
- Instantiate DMAs in `rtl/top.v` & connect to DMA controller
- Update `tb/top_ram.sv` with more AXI2RAM instances
- Update `tb/top_tb.sv` with more RAM ports and RAM read logic
- Update `c/firmware.c` with more register writes

### Adding a custom AXI Stream IP

- Simply instantiate the IP in `rtl/top.v` and connect it between the DMAs
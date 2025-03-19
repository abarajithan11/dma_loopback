# Define variables
BYTES = 1024
TB_MODULE = top_tb
BUILD_DIR = run/build
DATA_DIR = $(BUILD_DIR)/data
FULL_DATA_DIR = $(abspath $(DATA_DIR))
C_SOURCE = ../../c/sim.c
SOURCES_FILE = sources.txt
XSIM_CFG = ../xsim_cfg.tcl

# Compiler options
XSC_FLAGS = --gcc_compile_options -DSIM --gcc_compile_options -DBYTES=$(BYTES) --gcc_compile_options -DDIR=$(FULL_DATA_DIR)
XVLOG_FLAGS = -sv -d "DIR=$(FULL_DATA_DIR)" -d "BYTES=$(BYTES)" 
XELAB_FLAGS = --snapshot $(TB_MODULE) -log elaborate.log --debug typical -sv_lib dpi
XSIM_FLAGS = --tclbatch $(XSIM_CFG)
VERI_FLAGS = --binary -j 0 -O3 -DBYTES=$(BYTES) -DDIR=$(FULL_DATA_DIR) -CFLAGS -DSIM -CFLAGS -DBYTES=$(BYTES) -CFLAGS -DDIR=$(FULL_DATA_DIR) -CFLAGS -g --Mdir ../$(BUILD_DIR)

# Ensure the build directories exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(DATA_DIR): | $(BUILD_DIR)
	mkdir -p $(DATA_DIR)

# Compile C source
c: $(BUILD_DIR)
	cd $(BUILD_DIR) && xsc $(C_SOURCE) $(XSC_FLAGS)

# Run Verilog compilation
vlog: c
	cd $(BUILD_DIR) && xvlog -f ../$(SOURCES_FILE)  $(XVLOG_FLAGS)

# Elaborate design
elab: vlog
	cd $(BUILD_DIR) && xelab $(TB_MODULE) $(XELAB_FLAGS)

# Run simulation
xsim: elab $(DATA_DIR)
	cd $(BUILD_DIR) && xsim $(TB_MODULE) $(XSIM_FLAGS)

build_verilator: $(BUILD_DIR)
	cd run && verilator --top $(TB_MODULE) -F $(SOURCES_FILE) $(C_SOURCE) $(VERI_FLAGS)

veri: build_verilator $(DATA_DIR)
	cd $(BUILD_DIR) && ./V$(TB_MODULE)

# Clean build directory
clean:
	rm -rf $(BUILD_DIR)

.PHONY: sim vlog elab run clean


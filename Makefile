# Define variables
TB_MODULE = top_tb
BUILD_DIR = run/build
DATA_DIR = $(BUILD_DIR)/data
INPUT_FILE = $(DATA_DIR)/input.bin
C_SOURCE = ../../c/sim.c
SOURCES_FILE = ../sources.txt
XSIM_CFG = ../xsim_cfg.tcl

# Compiler options
XSC_FLAGS = --gcc_compile_options -DSIM
XELAB_FLAGS = --snapshot $(TB_MODULE) -log elaborate.log --debug typical -sv_lib dpi
XSIM_FLAGS = --tclbatch $(XSIM_CFG)

# Ensure the build directories exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(DATA_DIR): | $(BUILD_DIR)
	mkdir -p $(DATA_DIR)

# Create input.bin
$(INPUT_FILE): | $(DATA_DIR)
	printf "$(printf '\\%03o' {0..255})" | head -c 1024 > $@

# Compile C source
c: $(INPUT_FILE)
	cd $(BUILD_DIR) && xsc $(C_SOURCE) $(XSC_FLAGS)

# Run Verilog compilation
vlog: c
	cd $(BUILD_DIR) && xvlog -sv -f $(SOURCES_FILE)

# Elaborate design
elab: vlog
	cd $(BUILD_DIR) && xelab $(TB_MODULE) $(XELAB_FLAGS)

# Run simulation
xsim: elab
	cd $(BUILD_DIR) && xsim $(TB_MODULE) $(XSIM_FLAGS)

# Clean build directory
clean:
	rm -rf $(BUILD_DIR)

.PHONY: sim vlog elab run clean


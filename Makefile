# Makefile for axi_cnn Verilator testbench

# Name of the top Verilog module (without 'V' prefix)
TOP = axi_cnn

# C++ testbench
TB = tb.cpp

# All RTL source files (top-level SV + all dependent Verilog files)
RTL_SRCS = axi_cnn.sv \
           cnn_controller.v \
           conv.v \
           fc.v \
           mac.v \
           prepare_data.v \
           first_weights_seperate_filter.v \
           final_weights_seperate_class.v

# Verilator options
VERILATOR_FLAGS = -Wall --trace --timing

# Default target
all: run

# Generate C++ model with Verilator
obj_dir/V$(TOP).mk: $(RTL_SRCS) $(TB)
	verilator $(VERILATOR_FLAGS) --cc $(RTL_SRCS) --exe $(TB) --top-module $(TOP)

# Build the executable
build: obj_dir/V$(TOP).mk
	make -j -C obj_dir -f V$(TOP).mk V$(TOP)

# Run the simulation
run: build
	./obj_dir/V$(TOP)

# Clean generated files
clean:
	rm -rf obj_dir *.vcd *.o *.d *.exe

.PHONY: all build run clean
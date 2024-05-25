# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../rtl/uart_top.sv
VERILOG_SOURCES += $(PWD)/../rtl/uart_rx.sv
VERILOG_SOURCES += $(PWD)/../rtl/uart_tx.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = uart_top

# MODULE is the basename of the Python test file
MODULE = uart_test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
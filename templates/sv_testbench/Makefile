# @NAME@: SystemVerilog testbench compiled by Verilator --binary. Use inside `fpga-box shell`.  make [test|lint]
OUT ?= build
JOBS ?= 8
test: $(OUT)/Vtb_@NAME@
	$(OUT)/Vtb_@NAME@
$(OUT)/Vtb_@NAME@: @NAME@.sv tb_@NAME@.sv
	verilator --binary --timing --assert -j $(JOBS) -Wno-fatal --timescale 1ns/1ps --top-module tb_@NAME@ -Mdir $(OUT) $^
lint:
	verilator --lint-only -Wall @NAME@.sv
.PHONY: test lint

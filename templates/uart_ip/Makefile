# @NAME@: UART TX/RX IP with a loopback testbench. Use inside `fpga-box shell`.  make [test|test-verilator|lint|synth]
OUT ?= build
SRC := @NAME@_tx.v @NAME@_rx.v
test:
	mkdir -p $(OUT)
	iverilog -g2012 -Wall -Wno-timescale -o $(OUT)/tb.vvp $(SRC) tb_@NAME@.sv
	vvp -n $(OUT)/tb.vvp
test-verilator:
	verilator --binary --timing -j 8 -Wno-fatal --timescale 1ns/1ps --top-module tb_@NAME@ -Mdir $(OUT)/vl $(SRC) tb_@NAME@.sv
	$(OUT)/vl/Vtb_@NAME@
lint:
	verilator --lint-only -Wall @NAME@_tx.v
	verilator --lint-only -Wall @NAME@_rx.v
synth:
	yosys -q -p "read_verilog -sv $(SRC); hierarchy -top @NAME@_rx; synth_ice40; stat"
.PHONY: test test-verilator lint synth

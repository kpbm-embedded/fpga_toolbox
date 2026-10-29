# @NAME@: Icarus Verilog simulation. Use inside `fpga-box shell` (or native mode).  make [test|lint|wave]
OUT ?= build
test: $(OUT)/tb.vvp
	vvp -n $(OUT)/tb.vvp
$(OUT)/tb.vvp: @NAME@.v tb_@NAME@.sv
	mkdir -p $(OUT)
	iverilog -g2012 -Wall -o $@ $^
lint:
	verilator --lint-only -Wall @NAME@.v
wave: test
	gtkwave $(OUT)/@NAME@.vcd
.PHONY: test lint wave

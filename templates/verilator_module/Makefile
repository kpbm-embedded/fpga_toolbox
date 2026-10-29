# @NAME@: lint + Verilator C++ model + run. Use inside `fpga-box shell` (or native mode).
# make [lint|sim|run|wave]   OUT=build dir (default ./build)
OUT ?= build
JOBS ?= 8
TOP := @NAME@
lint:
	verilator --lint-only -Wall $(TOP).v
sim: lint
	verilator --cc --exe --build -j $(JOBS) --trace -Wall -Mdir $(OUT) $(TOP).v tb_$(TOP).cpp
run: sim
	cd $(OUT) && ./V$(TOP)
wave: run
	gtkwave $(OUT)/$(TOP).vcd
.PHONY: lint sim run wave

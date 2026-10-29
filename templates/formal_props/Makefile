# @NAME@: formal checks with yosys-smtbmc + z3 (no testbench). Use inside `fpga-box shell`.
# make prove = bmc + induction + cover; counterexamples/traces as VCD in build/.
OUT ?= build
DEPTH ?= 20
prove: bmc induction cover
$(OUT)/@NAME@.smt2: @NAME@.v
	mkdir -p $(OUT)
	yosys -q -p "read_verilog -sv -formal -DFORMAL $<; prep -top @NAME@; async2sync; dffunmap; write_smt2 -wires $@"
bmc: $(OUT)/@NAME@.smt2
	yosys-smtbmc -s z3 -t $(DEPTH) --dump-vcd $(OUT)/bmc.vcd $<
induction: $(OUT)/@NAME@.smt2
	yosys-smtbmc -s z3 -i -t $(DEPTH) $<
cover: $(OUT)/@NAME@.smt2
	yosys-smtbmc -s z3 -c -t $(DEPTH) --dump-vcd $(OUT)/cover.vcd $<
.PHONY: prove bmc induction cover

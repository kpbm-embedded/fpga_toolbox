# @NAME@: yosys -> nextpnr-ecp5 -> ecppack for the ULX3S. Use inside `fpga-box shell` (or native mode).
# Other ECP5 boards: change DEVICE/PACKAGE/LPF (OrangeCrab: --25k CSFBGA285, Colorlight i5: --25k CABGA381).
OUT ?= build
DEVICE ?= --85k
PACKAGE ?= CABGA381
LPF ?= ulx3s.lpf
all: $(OUT)/@NAME@.bit
$(OUT)/@NAME@.json: @NAME@.v
	mkdir -p $(OUT)
	yosys -q -l $(OUT)/yosys.log -p "synth_ecp5 -top top -json $@" $<
$(OUT)/@NAME@.config: $(OUT)/@NAME@.json $(LPF)
	nextpnr-ecp5 $(DEVICE) --package $(PACKAGE) --lpf $(LPF) --json $< --textcfg $@ --report $(OUT)/report.json -l $(OUT)/nextpnr.log -q
$(OUT)/@NAME@.bit: $(OUT)/@NAME@.config
	ecppack --compress $< $@
	@echo "bitstream $@ (program: openFPGALoader -b ulx3s $@, not part of fpga-box)"
test: all
	@python -c "import json; f = json.load(open(\"$(OUT)/report.json\"))[\"fmax\"]; v = min(x[\"achieved\"] for x in f.values()); print(\"fmax %.1f MHz\" % v); assert v >= 25, \"timing\"; print(\"PASS @NAME@\")"
.PHONY: all test

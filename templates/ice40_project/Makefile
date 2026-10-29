# @NAME@: yosys -> nextpnr-ice40 -> icepack. Use inside `fpga-box shell` (or native mode).
# For another iCE40 board change DEVICE/PACKAGE/PCF (e.g. --hx8k ct256 for iCE40-HX8K-EVB).
OUT ?= build
DEVICE ?= --up5k
PACKAGE ?= sg48
PCF ?= icebreaker.pcf
FREQ ?= 12
all: $(OUT)/@NAME@.bin
$(OUT)/@NAME@.json: @NAME@.v
	mkdir -p $(OUT)
	yosys -q -l $(OUT)/yosys.log -p "synth_ice40 -top top -json $@" $<
$(OUT)/@NAME@.asc: $(OUT)/@NAME@.json $(PCF)
	nextpnr-ice40 $(DEVICE) --package $(PACKAGE) --freq $(FREQ) --pcf $(PCF) --json $< --asc $@ --report $(OUT)/report.json -l $(OUT)/nextpnr.log
$(OUT)/@NAME@.bin: $(OUT)/@NAME@.asc
	icepack $< $@
	@echo "bitstream $@ (program: iceprog $@, not part of fpga-box)"
.PHONY: all

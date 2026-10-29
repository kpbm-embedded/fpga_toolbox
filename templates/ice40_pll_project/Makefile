# @NAME@: icepll -> yosys -> nextpnr-ice40 -> icepack. Use inside `fpga-box shell`.  make [all|test] FREQ_OUT=<MHz>
OUT ?= build
FREQ_OUT ?= 48
PCF ?= icebreaker.pcf
all: $(OUT)/@NAME@.bin
$(OUT)/pll.v:
	mkdir -p $(OUT)
	icepll -q -p -i 12 -o $(FREQ_OUT) -m -f $@
$(OUT)/@NAME@.json: @NAME@.v $(OUT)/pll.v
	yosys -q -l $(OUT)/yosys.log -p "synth_ice40 -top top -json $@" $^
$(OUT)/@NAME@.asc: $(OUT)/@NAME@.json $(PCF)
	nextpnr-ice40 --up5k --package sg48 --freq $(FREQ_OUT) --pcf $(PCF) --json $< --asc $@ --report $(OUT)/report.json -l $(OUT)/nextpnr.log -q
$(OUT)/@NAME@.bin: $(OUT)/@NAME@.asc
	icepack $< $@
	@grep -E "F_PLLOUT|achieved" $(OUT)/pll.v | head -2
test: all
	@python -c "import json; f = json.load(open(\"$(OUT)/report.json\"))[\"fmax\"]; v = min(x[\"achieved\"] for x in f.values()); print(\"fmax %.1f MHz (required $(FREQ_OUT))\" % v); assert v >= $(FREQ_OUT); print(\"PASS @NAME@\")"
.PHONY: all test

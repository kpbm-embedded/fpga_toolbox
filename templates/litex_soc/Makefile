# @NAME@: LiteX SoC for the iCEBreaker with an own peripheral. Use inside `fpga-box shell`.
# make export (Verilog, CSR map, BIOS) | make bitstream (+ yosys, nextpnr-ice40, icepack) | make test
export PYTHONDONTWRITEBYTECODE=1
OUT ?= build
G := $(OUT)/gateware
FREQ ?= 16
export:
	python @NAME@.py export --output-dir $(OUT)
bitstream: export
	cd $(G) && yosys -q -l icebreaker.rpt icebreaker.ys
	cd $(G) && nextpnr-ice40 --json icebreaker.json --pcf icebreaker.pcf --asc icebreaker.asc --up5k --package sg48 --freq $(FREQ) --report report.json -q
	cd $(G) && icepack -s icebreaker.asc icebreaker.bin
	@echo "bitstream $(G)/icebreaker.bin + BIOS $(OUT)/software/bios/bios.bin (flash at 0x40000; not part of fpga-box)"
test: export
	grep -q "^csr_register,pwm_period," $(OUT)/csr.csv
	test -s $(OUT)/software/bios/bios.bin
	@echo "PASS @NAME@: pwm registers in csr.csv, BIOS built"
.PHONY: export bitstream test

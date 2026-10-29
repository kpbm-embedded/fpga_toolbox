# @NAME@: Verilator coverage (line, toggle, user cover points). Use inside `fpga-box shell`.  make [test|cover]
OUT ?= build
JOBS ?= 8
MIN ?= 90
$(OUT)/Vtb_@NAME@: @NAME@.sv tb_@NAME@.sv
	verilator --binary --timing --assert --coverage -j $(JOBS) -Wno-fatal --timescale 1ns/1ps --top-module tb_@NAME@ -Mdir $(OUT) $(abspath $^)
test: cover
cover: $(OUT)/Vtb_@NAME@
	cd $(OUT) && ./Vtb_@NAME@ +verilator+coverage+file+coverage.dat
	verilator_coverage --annotate $(OUT)/annotated --annotate-all $(OUT)/coverage.dat
	verilator_coverage --write-info $(OUT)/coverage.info $(OUT)/coverage.dat
	@awk -F"[:,]" -v min=$(MIN) '/^SF:/ {d = ($$0 ~ /@NAME@\.sv$$/)} d && /^DA:/ {n++; if ($$3 > 0) h++} END {p = n ? 100 * h / n : 0; printf "@NAME@.sv line coverage %d/%d = %.1f %% (min %d)\n", h, n, p, min; exit (p < min)}' $(OUT)/coverage.info
.PHONY: test cover

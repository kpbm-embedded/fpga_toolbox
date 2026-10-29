#!/usr/bin/env bash
# shellcheck disable=SC2016  # check() command strings are expanded by the inner bash
# Smoke test of the fpga-box env: every tool starts and does one small real job.
# Then every template is created with `fpga-box new` in a temp dir and its own make target must pass.
# Usage: tests/test_smoke.sh      (examples: ./fpga-box examples test)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
R="$HERE/fpga-box"
pass=0; failn=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT   # own temp files only
check() { # name cmd-string (run inside the env, in $tmp)
  local name=$1 out
  if out=$("$R" shell -- bash -c "cd '$tmp' && $2" 2>&1); then printf 'ok    %s: %s\n' "$name" "$(tail -1 <<<"$out")"; pass=$((pass+1))
  else printf 'FAIL  %s\n%s\n' "$name" "$(tail -6 <<<"$out" | sed 's/^/      /')"; failn=$((failn+1)); fi
}
cat >"$tmp/and2.v" <<'V'
module and2(input wire a, b, output wire y); assign y = a & b; endmodule
V
cat >"$tmp/tb.sv" <<'V'
module tb; logic a, b; wire y; and2 u(.a, .b, .y);
initial begin a = 1; b = 1; #1 if (y !== 1) $fatal(1, "and2"); $display("PASS sv"); $finish; end endmodule
V
check yosys        'yosys -q -p "synth -top and2; stat" and2.v | grep -E "cells|Number of cells" | head -1; echo yosys $(yosys -V | cut -d" " -f2)'
check verilator    'verilator --binary -j 4 -Mdir obj tb.sv and2.v >/dev/null && obj/Vtb | head -1'
check iverilog     'iverilog -g2012 -o t.vvp tb.sv and2.v && vvp -n t.vvp | head -1'
check nextpnr-ice40 'yosys -q -p "synth_ice40 -top and2 -json a.json" and2.v && nextpnr-ice40 --hx1k --package tq144 --json a.json --asc a.asc -q && icepack a.asc a.bin && echo "bitstream $(wc -c <a.bin) bytes"'
check nextpnr-ecp5 'yosys -q -p "synth_ecp5 -top and2 -json e.json" and2.v && nextpnr-ecp5 --25k --json e.json --textcfg e.cfg -q && ecppack e.cfg e.bit && echo "bitstream $(wc -c <e.bit) bytes"'
check riscv-gcc    'echo "int f(int x){return x*3;}" > f.c && riscv64-linux-gnu-gcc -march=rv32im -mabi=ilp32 -ffreestanding -c f.c -o f.o && riscv64-linux-gnu-objdump -f f.o | grep -o "elf32-littleriscv"'
check litex        'python -c "import litex, migen, litex_boards, liteeth, litedram; from litex.soc.cores.cpu.vexriscv import VexRiscv; print(\"litex imports ok\")"'
check formal-tools 'yosys-smtbmc --help >/dev/null 2>&1; z3 --version'
check cocotb       'python -c "import cocotb_tools.runner, cocotb; print(\"cocotb runner ok\")"'
check amaranth     'python -c "import amaranth; print(\"amaranth\", amaranth.__version__)"'
# templates: kind -> make target (each writes only into its own folder under $tmp)
declare -A TPL=([verilator_module]=run [ice40_project]=all [icarus_tb]=test [sv_testbench]=test [cocotb_test]=test-all
  [formal_props]=prove [ecp5_project]=test [amaranth_module]=test [uart_ip]=test [equiv_check]=test [litex_soc]=test
  [coverage_tb]=test [ice40_pll_project]=test)
for k in $(printf '%s\n' "${!TPL[@]}" | sort); do
  if "$R" new "$k" "t_$k" --dir "$tmp" >/dev/null 2>&1; then check "template $k" "make -s -C t_$k ${TPL[$k]} 2>&1 | tail -3"
  else printf 'FAIL  template %s: new failed\n' "$k"; failn=$((failn+1)); fi
done
n_tpl=$(find "$HERE/templates" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$n_tpl" -eq "${#TPL[@]}" ]; then printf 'ok    every template is tested (%s)\n' "$n_tpl"; pass=$((pass+1))
else printf 'FAIL  templates/ has %s kinds, the smoke test knows %s\n' "$n_tpl" "${#TPL[@]}"; failn=$((failn+1)); fi
echo "smoke: $pass ok, $failn failed"
[ "$failn" -eq 0 ]

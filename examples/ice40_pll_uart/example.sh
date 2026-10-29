#!/usr/bin/env bash
# about: iCE40 PLL + UART: icepll makes a 48 MHz pad PLL from 12 MHz, UART TX at 115200 on iCEBreaker; checks SB_PLL40_PAD in the netlist and Fmax >= 48 MHz (no board: build only)
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  icepll -q -p -i 12 -o 48 -m -f "$out/pll.v"
  yosys -q -l "$out/yosys.log" -p "read_verilog -sv $out/pll.v ../common/rtl/uart_tx.v top.v
    synth_ice40 -top top -json $out/top.json; tee -o $out/stat.txt stat"
  nextpnr-ice40 --up5k --package sg48 --freq 48 --pcf icebreaker.pcf --json "$out/top.json" --asc "$out/top.asc" \
    --report "$out/report.json" -l "$out/nextpnr.log" -q
  icepack "$out/top.asc" "$out/top.bin"
  echo "bitstream $out/top.bin ($(wc -c <"$out/top.bin") bytes); program with iceprog, then: serial-box tio /dev/ttyUSB1 -b 115200"
}
check() {
  grep -E 'F_PLLOUT|DIVR|DIVF|DIVQ' "$out/pll.v" | sed 's/^ */  /' | head -5
  grep -q SB_PLL40_PAD "$out/stat.txt" && echo "netlist uses SB_PLL40_PAD"
  python - "$out/report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
fmax = {k: round(v["achieved"], 1) for k, v in r["fmax"].items()}
print("fmax MHz per clock:", fmax)
fast = [v for k, v in fmax.items() if "48" in k or "clk48" in k or "PLLOUT" in k.upper()] or list(fmax.values())
sys.exit(0 if min(fast) >= 48 else 1)
PY
}
case "$act" in
  build) build ;;
  run|test) build; check | tee "$out/run.log"; grep -q SB_PLL40_PAD "$out/run.log"; echo "PASS ice40_pll_uart" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: Amaranth HDL 0.5 (Python): breathing-LED PWM simulated in Python, exported to Verilog, built for iCEBreaker (yosys, nextpnr-ice40, icepack)
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
export PYTHONDONTWRITEBYTECODE=1
build() {
  python breathe.py verilog "$out/breathe.v"
  yosys -q -l "$out/yosys.log" -p "synth_ice40 -top top -json $out/top.json" "$out/breathe.v" top.v
  nextpnr-ice40 --up5k --package sg48 --freq 12 --pcf icebreaker.pcf --json "$out/top.json" --asc "$out/top.asc" \
    --report "$out/report.json" -l "$out/nextpnr.log" -q
  icepack "$out/top.asc" "$out/top.bin"
  echo "bitstream $out/top.bin ($(wc -c <"$out/top.bin") bytes); program with iceprog (not run here)"
}
fmax() { python -c 'import json,sys; f=json.load(open(sys.argv[1]))["fmax"]; v=min(x["achieved"] for x in f.values()); print(f"fmax {v:.1f} MHz (12 required)"); sys.exit(v < 12)' "$out/report.json"; }
case "$act" in
  build) build ;;
  run)   python breathe.py sim; build; fmax ;;
  test)  python breathe.py sim | tee "$out/run.log"; build; fmax | tee -a "$out/run.log"
         grep -q '^PASS amaranth sim' "$out/run.log"; [ "$(wc -c <"$out/top.bin")" -gt 100000 ]; echo "PASS amaranth_ice40" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: ECP5 flow for ULX3S (LFE5U-85F): yosys synth_ecp5 -> nextpnr-ecp5 -> ecppack bitstream + Fmax check
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  yosys -q -l "$out/yosys.log" -p "synth_ecp5 -top top -json $out/blinky.json" blinky.v
  nextpnr-ecp5 --85k --package CABGA381 --speed 6 --freq 25 --lpf ulx3s.lpf --json "$out/blinky.json" \
    --textcfg "$out/blinky.config" --report "$out/report.json" -l "$out/nextpnr.log" -q
  ecppack --compress "$out/blinky.config" "$out/blinky.bit"
  echo "bitstream $out/blinky.bit ($(wc -c <"$out/blinky.bit") bytes); program with openFPGALoader -b ulx3s (not run here)"
}
check() {
  python - "$out/report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
fmax = {k: v["achieved"] for k, v in r.get("fmax", {}).items()}
util = {k: v["used"] for k, v in r.get("utilization", {}).items() if v["used"]}
print("fmax MHz:", {k: round(v, 1) for k, v in fmax.items()}, "| used:", util)
ok = fmax and all(v >= 25 for v in fmax.values())
print("PASS ecp5 timing (>= 25 MHz)" if ok else "FAIL timing")
sys.exit(0 if ok else 1)
PY
  [ "$(wc -c <"$out/blinky.bit")" -gt 10000 ]
}
case "$act" in
  build) build ;;
  run)   build; check ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

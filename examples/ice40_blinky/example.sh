#!/usr/bin/env bash
# about: iCE40 flow for iCEBreaker (UP5K): yosys synth_ice40 -> nextpnr-ice40 -> icepack bitstream + Fmax check
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  yosys -q -l "$out/yosys.log" -p "synth_ice40 -top top -json $out/blinky.json" blinky.v
  nextpnr-ice40 --up5k --package sg48 --freq 12 --pcf icebreaker.pcf --json "$out/blinky.json" \
    --asc "$out/blinky.asc" --report "$out/report.json" -l "$out/nextpnr.log" -q
  icepack "$out/blinky.asc" "$out/blinky.bin"
  echo "bitstream $out/blinky.bin ($(wc -c <"$out/blinky.bin") bytes); program with iceprog (not run here)"
}
check() {
  python - "$out/report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
fmax = {k: v["achieved"] for k, v in r.get("fmax", {}).items()}
util = {k: v["used"] for k, v in r.get("utilization", {}).items() if v["used"]}
print("fmax MHz:", {k: round(v, 1) for k, v in fmax.items()}, "| used:", util)
ok = fmax and all(v >= 12 for v in fmax.values())
print("PASS ice40 timing (>= 12 MHz)" if ok else "FAIL timing")
sys.exit(0 if ok else 1)
PY
  [ "$(wc -c <"$out/blinky.bin")" -gt 100000 ]
}
case "$act" in
  build) build ;;
  run)   build; check ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

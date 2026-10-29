#!/usr/bin/env bash
# about: LiteX SoC for a real board (iCEBreaker, litex-boards): VexRiscv + BIOS, LiteX exports gateware + builds the BIOS, then yosys/nextpnr-ice40/icepack; checks utilisation and 16 MHz timing (no board: build only)
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
# YoWASP nextpnr has no Python, so LiteX's own run (nextpnr --pre-pack script) cannot be used: LiteX exports
# the gateware (Verilog, .ys, .pcf) and compiles the BIOS; the place and route below gives the clock with --freq.
args=(--build --no-compile-gateware --output-dir "$out/soc" --cpu-type vexriscv --cpu-variant minimal --sys-clk-freq 16e6 --bios-console lite)
build() {
  (cd "$out" && python -m litex_boards.targets.icebreaker "${args[@]}" >"$out/build.log" 2>&1) || { tail -30 "$out/build.log"; exit 1; }
  local g="$out/soc/gateware"
  (cd "$g" && yosys -q -l icebreaker.rpt icebreaker.ys \
    && nextpnr-ice40 --json icebreaker.json --pcf icebreaker.pcf --asc icebreaker.asc --up5k --package sg48 --freq 16 \
         --seed 1 --report report.json -l nextpnr.log -q \
    && icepack -s icebreaker.asc icebreaker.bin) || { tail -20 "$g/nextpnr.log"; exit 1; }
  local f; for f in "$out/soc/gateware/icebreaker.bin" "$out/soc/software/bios/bios.bin"; do echo "$f $(wc -c <"$f") bytes"; done
  echo "flash (not run here): bitstream at 0, bios.bin at the --bios-flash-offset (see the target's --help)"
}
check() {
  python - "$out/soc/gateware/report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
util = {k: f"{v['used']}/{v['available']}" for k, v in r["utilization"].items() if v["used"]}
fmax = {k: round(v["achieved"], 1) for k, v in r["fmax"].items()}
print("utilisation:", util)
print("fmax MHz:", fmax, "(16 required)")
sys.exit(0 if fmax and min(fmax.values()) >= 16 else 1)
PY
}
case "$act" in
  build) build ;;
  run|test) build; check | tee "$out/run.log"; echo "PASS litex_icebreaker_soc" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

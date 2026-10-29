#!/usr/bin/env bash
# about: SystemVerilog testbench on Verilator --binary (timing, concurrent assertion): PWM duty measured per period, glitch-free mid-period update
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  verilator --binary --timing --assert -j "${BOXT_JOBS:-4}" --trace -Wno-fatal --top-module tb -Mdir "$out/obj" \
    ../common/rtl/pwm.v tb.sv >"$out/verilator.log" 2>&1 || { tail -20 "$out/verilator.log"; exit 1; }
  echo "built $out/obj/Vtb"
}
sim() { (cd "$out" && ./obj/Vtb +vcd); }
case "$act" in
  build) build ;;
  run)   [ -x "$out/obj/Vtb" ] || build; sim ;;
  test)  build; sim | tee "$out/run.log"; grep -q '^PASS' "$out/run.log"; [ -s "$out/pwm.vcd" ] ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

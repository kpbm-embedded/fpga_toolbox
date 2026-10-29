#!/usr/bin/env bash
# about: Icarus Verilog testbench: 4-bit counter (enable, clear, wrap) with self-checks + VCD
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() { iverilog -g2012 -Wall -DVCD="\"$out/counter.vcd\"" -o "$out/tb.vvp" counter.v tb.v; echo "built $out/tb.vvp"; }
case "$act" in
  build) build ;;
  run)   [ -r "$out/tb.vvp" ] || build; vvp -n "$out/tb.vvp" ;;
  test)  build; vvp -n "$out/tb.vvp" | tee "$out/run.log"; grep -q '^PASS' "$out/run.log" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

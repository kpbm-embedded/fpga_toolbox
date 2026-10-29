#!/usr/bin/env bash
# about: Icarus Verilog: 8N1 UART receiver (synchroniser, mid-bit sampling) - 6 bytes, glitch rejected, framing error flagged
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() { iverilog -g2012 -Wall -DVCD="\"$out/uart_rx.vcd\"" -o "$out/tb.vvp" ../common/rtl/uart_rx.v tb.sv; echo "built $out/tb.vvp"; }
case "$act" in
  build) build ;;
  run)   [ -r "$out/tb.vvp" ] || build; vvp -n "$out/tb.vvp" ;;
  test)  build; vvp -n "$out/tb.vvp" | tee "$out/run.log"; grep -q '^PASS' "$out/run.log"; [ -s "$out/uart_rx.vcd" ] ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

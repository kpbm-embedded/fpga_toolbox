#!/usr/bin/env bash
# about: Verilator C++ testbench: 8N1 UART transmitter, line decoder + byte assertions, VCD
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  verilator --lint-only -Wall uart_tx.v
  verilator --cc --exe --build -j "${BOXT_JOBS:-4}" --trace -Wall -Wno-fatal -Mdir "$out/obj" uart_tx.v tb.cpp >"$out/verilator.log" 2>&1 \
    || { tail -20 "$out/verilator.log"; exit 1; }
  echo "built $out/obj/Vuart_tx"
}
case "$act" in
  build) build ;;
  run)   [ -x "$out/obj/Vuart_tx" ] || build; VCD="$out/uart_tx.vcd" "$out/obj/Vuart_tx" ;;
  test)  build; VCD="$out/uart_tx.vcd" "$out/obj/Vuart_tx" | tee "$out/run.log"; grep -q '^PASS' "$out/run.log"; [ -s "$out/uart_tx.vcd" ] ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

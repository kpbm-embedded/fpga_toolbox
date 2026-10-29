#!/usr/bin/env bash
# about: Verilator C++ testbench: SPI master in all 4 modes (CPOL/CPHA) against a behavioural slave, full-duplex bytes, edge count, CS framing, VCD
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
src=../common/rtl/spi_master.v
build() {
  verilator --lint-only -Wall "$src"
  verilator --cc --exe --build -j "${BOXT_JOBS:-4}" --trace -Wall -Wno-fatal -Mdir "$out/obj" "$src" tb.cpp >"$out/verilator.log" 2>&1 \
    || { tail -20 "$out/verilator.log"; exit 1; }
  echo "built $out/obj/Vspi_master"
}
case "$act" in
  build) build ;;
  run)   [ -x "$out/obj/Vspi_master" ] || build; VCD="$out/spi.vcd" "$out/obj/Vspi_master" ;;
  test)  build; VCD="$out/spi.vcd" "$out/obj/Vspi_master" | tee "$out/run.log"; grep -q '^PASS' "$out/run.log"; [ -s "$out/spi.vcd" ] ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

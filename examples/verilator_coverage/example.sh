#!/usr/bin/env bash
# about: Verilator --coverage (line + toggle) on the uart_rx testbench: coverage.dat, verilator_coverage annotated source, line coverage >= 90 %
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
MIN=${COVERAGE_MIN:-90}
build() {
  verilator --binary --timing --coverage-line --coverage-toggle -j "${BOXT_JOBS:-4}" -Wno-fatal --top-module tb \
    -Mdir "$out/obj" "$(cd ../common/rtl && pwd)/uart_rx.v" "$(cd ../uart_rx_icarus && pwd)/tb.sv" >"$out/verilator.log" 2>&1 \
    || { tail -20 "$out/verilator.log"; exit 1; }
  echo "built $out/obj/Vtb (coverage instrumented)"
}
cover() {
  (cd "$out" && ./obj/Vtb +verilator+coverage+file+coverage.dat) | grep -E 'PASS|FAIL|received'
  verilator_coverage --annotate "$out/annotated" --annotate-all --annotate-min 1 "$out/coverage.dat" 2>&1 | tail -3
  verilator_coverage --write-info "$out/coverage.info" "$out/coverage.dat"
  # line coverage of the DUT from the lcov file (LF = lines found, LH = lines hit)
  awk -F'[:,]' -v min="$MIN" '/^SF:/ {dut = ($0 ~ /uart_rx\.v$/)} dut && /^DA:/ {lf++; if ($3 > 0) lh++}
    END {pct = lf ? 100 * lh / lf : 0; printf "uart_rx.v line coverage: %d/%d = %.1f %% (minimum %d %%)\n", lh, lf, pct, min; exit (pct >= min) ? 0 : 1}' "$out/coverage.info"
  echo "annotated source: $out/annotated/uart_rx.v (lines marked %000000 were never run)"
}
case "$act" in
  build) build ;;
  run)   [ -x "$out/obj/Vtb" ] || build; cover ;;
  test)  build; cover | tee "$out/run.log"; grep -q '^PASS uart_rx' "$out/run.log"; [ -s "$out/annotated/uart_rx.v" ]
         echo "PASS verilator_coverage" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

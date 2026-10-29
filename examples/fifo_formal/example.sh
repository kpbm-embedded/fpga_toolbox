#!/usr/bin/env bash
# about: formal verification without a testbench: sync FIFO properties proven by yosys-smtbmc + z3 (BMC, k-induction, cover); a seeded bug must fail with a counterexample VCD
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
DEPTH=${FORMAL_DEPTH:-20}
smt2() { # src.v out.smt2: the design with its assert/assume/cover as an SMT-LIB2 model
  yosys -q -l "$out/yosys_$(basename "$2" .smt2).log" \
    -p "read_verilog -formal -DFORMAL $1; prep -top sync_fifo; async2sync; dffunmap; write_smt2 -wires $2"
}
build() {
  smt2 ../common/rtl/sync_fifo.v "$out/fifo.smt2"
  # seeded bug: writes while full are no longer blocked (overwrites unread data)
  sed 's/wire do_wr = wr_en \&\& !full;/wire do_wr = wr_en;/' ../common/rtl/sync_fifo.v >"$out/sync_fifo_bug.v"
  grep -q 'wire do_wr = wr_en;' "$out/sync_fifo_bug.v"
  smt2 "$out/sync_fifo_bug.v" "$out/fifo_bug.smt2"
  echo "built $out/fifo.smt2 and fifo_bug.smt2"
}
prove() {
  local rc=0
  echo "== BMC: every assertion holds for $DEPTH cycles from reset"
  yosys-smtbmc -s z3 -t "$DEPTH" "$out/fifo.smt2" >"$out/bmc.log" || rc=1; tail -1 "$out/bmc.log"
  echo "== k-induction: the assertions hold for any number of cycles"
  yosys-smtbmc -s z3 -i -t "$DEPTH" "$out/fifo.smt2" >"$out/induction.log" || rc=1; tail -1 "$out/induction.log"
  echo "== cover: a trace that fills the FIFO exists"
  yosys-smtbmc -s z3 -c -t "$DEPTH" --dump-vcd "$out/cover.vcd" "$out/fifo.smt2" >"$out/cover.log" || rc=1; tail -1 "$out/cover.log"
  echo "== seeded bug: BMC must find a counterexample"
  if yosys-smtbmc -s z3 -t "$DEPTH" --dump-vcd "$out/bug_cex.vcd" "$out/fifo_bug.smt2" >"$out/bug.log"; then
    echo "bug NOT found"; rc=1
  else grep -m1 'Assert failed' "$out/bug.log" || true; echo "counterexample: $out/bug_cex.vcd"; fi
  return "$rc"
}
case "$act" in
  build) build ;;
  run)   build; prove ;;
  test)  build; prove | tee "$out/run.log"
         [ "$(grep -c 'Status: PASSED' "$out/run.log")" -eq 3 ] && [ -s "$out/cover.vcd" ] && [ -s "$out/bug_cex.vcd" ]
         echo "PASS fifo_formal (BMC + induction + cover, seeded bug caught)" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

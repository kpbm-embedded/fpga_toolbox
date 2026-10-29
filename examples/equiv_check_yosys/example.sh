#!/usr/bin/env bash
# about: Yosys formal equivalence: adder-tree popcount and a Gray-only counter proven equal to reference RTL (equiv_make/simple/induct); a seeded bug is caught
# shellcheck disable=SC2016  # yosys cell names ($equiv) are literal
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
check() { # top defines -> yosys log in $out, exit status of equiv_status -assert
  sed -e "s/@TOP@/$1/g" -e "s/@DEFS@/$2/g" equiv.ys.in >"$out/equiv_$1$3.ys"
  yosys -q -l "$out/equiv_$1$3.log" -s "$out/equiv_$1$3.ys" >/dev/null 2>&1
}
prove() {
  local rc=0 t
  for t in popcount8 gray4; do
    if check "$t" "" ""; then echo "equivalent: $t ($(grep -m1 -o 'Found [0-9]* \$equiv cells.*' "$out/equiv_$t.log" || echo proven))"
    else echo "NOT equivalent: $t (see $out/equiv_$t.log)"; rc=1; fi
  done
  if check popcount8 "-DBUG" _bug; then echo "seeded bug NOT detected"; rc=1
  else echo "seeded bug detected: $(grep -m1 -o 'Found [0-9]* unproven \$equiv cells' "$out/equiv_popcount8_bug.log" || echo unproven cells)"; fi
  return "$rc"
}
case "$act" in
  build) echo "nothing to build (yosys reads the sources)" ;;
  run)   prove ;;
  test)  prove | tee "$out/run.log"; echo "PASS equiv_check_yosys" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

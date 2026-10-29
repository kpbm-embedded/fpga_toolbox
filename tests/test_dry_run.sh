#!/usr/bin/env bash
# Every fpga-box command in --dry-run mode (no downloads, builds, moves or launches), the
# read-only commands for real, plus shellcheck. Usage: tests/test_dry_run.sh
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
R="$HERE/fpga-box"
pass=0; failn=0
check() { # name expected-regex cmd...
  local name=$1 re=$2; shift 2
  local out rc
  out=$(timeout 300 "$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && grep -qE -- "$re" <<<"$out"; then printf 'ok    %s\n' "$name"; pass=$((pass+1))
  else printf 'FAIL  %s (rc=%s)\n%s\n' "$name" "$rc" "$(tail -5 <<<"$out" | sed 's/^/      /')"; failn=$((failn+1)); fi
}
check help        'usage: ./fpga-box'                      "$R" help
check where       '^build '                                "$R" where
check status      'pixi-env'                               "$R" status
check bootstrap   '\+ timeout .* install'                  "$R" --dry-run bootstrap
check install     'examples build|\+ \(cd'                 "$R" --dry-run install
check update      'pinned vs newest'                       "$R" --dry-run update
check update-env  '\+ timeout .* update'                   "$R" --dry-run update --env
check clean       'nothing to clean|dry run: re-run with --yes' "$R" clean
check clean-all   'dry run: re-run with --yes'             "$R" clean --all
check doctor      'doctor: [0-9]+ ok'                      bash -c "'$R' doctor || true"
check shell       '\+ true'                                "$R" --dry-run shell -- true
check run         '\+ yosys -V'                            "$R" --dry-run run yosys -V
check tools       'yosys .*0\.69'                          "$R" tools
check sim         '\+ verilator --binary'                  "$R" --dry-run sim top.sv
check litex-sim   '\+ litex_sim --cpu-type vexriscv'       "$R" --dry-run litex-sim --cpu-type vexriscv
check wave        '\+ gtkwave x.vcd'                       "$R" --dry-run wave x.vcd
check new         '\+ copy .*verilator_module'             "$R" --dry-run new verilator_module foo
check examples    'litex_sim_vexriscv'                     "$R" examples list
check ex-test     'bash example.sh test'                   "$R" --dry-run examples test icarus_counter
check ex-run      'bash example.sh run'                    "$R" --dry-run examples run icarus_counter
check native      '\+   yosys .pixi'                       "$R" --dry-run native
check native-print 'nextpnr-ice40 @run'                    "$R" native --print
check relocate    'already matches|re-creating'            "$R" --dry-run relocate
check pack        '\+ tar '                                "$R" --dry-run pack
if command -v shellcheck >/dev/null; then
  if out=$(cd "$HERE" && shellcheck -x fpga-box lib/*.bash tests/*.sh examples/*/example.sh 2>&1); then printf 'ok    shellcheck\n'; pass=$((pass+1))
  else printf 'FAIL  shellcheck\n%s\n' "$(head -30 <<<"$out")"; failn=$((failn+1)); fi
else echo "skip  shellcheck (not installed)"; fi
echo "dry-run: $pass ok, $failn failed"
[ "$failn" -eq 0 ]

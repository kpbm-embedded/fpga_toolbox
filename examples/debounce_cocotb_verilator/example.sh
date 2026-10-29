#!/usr/bin/env bash
# about: cocotb 2.1 + Verilator: push-button debouncer, random contact bounce, one rise/fall per press, latency and glitch checks
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
export PYTHONDONTWRITEBYTECODE=1
case "$act" in
  build) python -c "import cocotb_tools.runner" && echo "cocotb ready (run.py builds + runs)" ;;
  run|test) python run.py "$out/sim" "${BOXT_JOBS:-4}" >"$out/run.log" 2>&1 || { tail -30 "$out/run.log"; exit 1; }
            grep -E 'PASS|FAIL|TESTS=' "$out/run.log"; grep -q '^PASS' "$out/run.log" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

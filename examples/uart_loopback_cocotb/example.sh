#!/usr/bin/env bash
# about: cocotb 2.1 + Icarus: UART TX->RX loopback, 64 random bytes via a Python monitor, bit-level driver injects a framing error
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
export PYTHONDONTWRITEBYTECODE=1   # no __pycache__ in the source folder
case "$act" in
  build) python -c "import cocotb_tools.runner" && echo "cocotb ready (run.py builds + runs)" ;;
  run|test) python run.py "$out/sim" 2>&1 | tee "$out/run.log"; grep -q '^PASS' "$out/run.log" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: LiteX SoC (VexRiscv, 2026.08) simulated by Verilator: BIOS boots to litex>, runs `ident`; exports csr.json + Renode .repl/.resc
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
TIMEOUT=${LITEX_SIM_TIMEOUT:-1500}   # first build (Verilator, ~4 min on 8 jobs) included
soc=(--cpu-type vexriscv --integrated-main-ram-size 0x10000 --non-interactive --jobs "${BOXT_JOBS:-8}"
     --output-dir "$out/soc" --soc-csv "$out/soc/csr.csv" --soc-json "$out/soc/csr.json")
strip_ansi() { sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' "$1"; }
has() { [ "$(strip_ansi "$1" | grep -c -- "$2")" -gt 0 ]; }   # grep -c reads all input: no SIGPIPE under pipefail

# Build gateware + BIOS and run until the BIOS prompt; then type `ident` and wait for the reply.
boot() {
  mkdir -p "$out/soc"; local log="$out/sim.log" fifo="$out/stdin.fifo" pid rc=1
  [ -p "$fifo" ] || mkfifo "$fifo"
  exec 3<>"$fifo"
  ( cd "$out" && exec timeout "$TIMEOUT" litex_sim "${soc[@]}" <"$fifo" >"$log" 2>&1 ) &
  pid=$!
  for _ in $(seq 1 $((TIMEOUT / 2))); do
    sleep 2
    has "$log" 'litex> ' && break
    kill -0 "$pid" 2>/dev/null || break
  done
  if has "$log" 'litex> '; then
    printf 'ident\r\n' >&3
    for _ in $(seq 1 60); do sleep 1; has "$log" '^Ident: ' && { rc=0; break; }; done
  fi
  kill "$pid" 2>/dev/null || true
  pkill -P "$pid" 2>/dev/null || true
  pgrep -f "^$out/soc/gateware/obj_dir/Vsim" >/dev/null 2>&1 && pkill -f "^$out/soc/gateware/obj_dir/Vsim" || true
  wait "$pid" 2>/dev/null || true
  exec 3>&-
  strip_ansi "$log" | sed -n '/BIOS built/,$p' | grep -vE '^\s*$' | sed -n 1,40p
  return "$rc"
}
renode_files() {   # LiteX -> Renode: the same SoC as a Renode platform
  litex_json2renode "$out/soc/csr.json" --repl "$out/renode/litex_sim.repl" --resc "$out/renode/litex_sim.resc" \
    --bios-binary "$out/soc/software/bios/bios.bin" >/dev/null 2>&1 || { mkdir -p "$out/renode"; litex_json2renode "$out/soc/csr.json" --repl "$out/renode/litex_sim.repl" --resc "$out/renode/litex_sim.resc" --bios-binary "$out/soc/software/bios/bios.bin"; }
  echo "renode platform: $out/renode/litex_sim.repl (+ .resc); load it with 32_06_renode"
}
case "$act" in
  build|run) mkdir -p "$out/renode"; boot; renode_files ;;
  test)
    mkdir -p "$out/renode"
    boot | tee "$out/run.log"
    grep -q 'CPU:.*VexRiscv' "$out/run.log" && grep -q '^Ident: ' "$out/run.log"
    renode_files; grep -q 'cpu' "$out/renode/litex_sim.repl"
    echo "PASS litex_sim vexriscv (BIOS prompt + ident)" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

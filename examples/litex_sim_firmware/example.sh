#!/usr/bin/env bash
# about: own C firmware on a LiteX SoC: headers from litex_sim, litex_bare_metal_demo built with the RISC-V gcc, loaded with --ram-init, BIOS boots it, its shell runs `helloc` (Verilator; first run several minutes)
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
TIMEOUT=${LITEX_SIM_TIMEOUT:-1500}
soc=(--cpu-type vexriscv --integrated-main-ram-size 0x10000 --jobs "${BOXT_JOBS:-8}" --output-dir "$out/soc")
strip_ansi() { sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' "$1"; }
has() { [ "$(strip_ansi "$1" | grep -c -- "$2")" -gt 0 ]; }

build() {
  # 1. SoC headers + libraries (generated/, libbase, BIOS) without the Verilator gateware build
  (cd "$out" && litex_sim "${soc[@]}" --no-compile-gateware >"$out/soc.log" 2>&1) || { tail -20 "$out/soc.log"; exit 1; }
  # 2. the demo application (litex/soc/software/demo: main.c, isr.c, a small shell) against those headers
  (cd "$out" && litex_bare_metal_demo --build-path "$out/soc" --mem main_ram >"$out/demo.log" 2>&1) || { tail -20 "$out/demo.log"; exit 1; }
  echo "demo.bin $(wc -c <"$out/demo.bin") bytes"
}
boot() { # run the SoC with demo.bin preloaded in main RAM, wait for the app prompt, type `helloc`
  local log="$out/sim.log" fifo="$out/stdin.fifo" pid rc=1
  [ -p "$fifo" ] || mkfifo "$fifo"
  exec 3<>"$fifo"
  ( cd "$out" && exec timeout "$TIMEOUT" litex_sim "${soc[@]}" --non-interactive --ram-init "$out/demo.bin" <"$fifo" >"$log" 2>&1 ) &
  pid=$!
  for _ in $(seq 1 $((TIMEOUT / 2))); do
    sleep 2; has "$log" 'litex-demo-app>' && break; kill -0 "$pid" 2>/dev/null || break
  done
  if has "$log" 'litex-demo-app>'; then
    printf 'helloc\n' >&3
    for _ in $(seq 1 60); do sleep 1; has "$log" 'C: Hello, world' && { rc=0; break; }; done
  fi
  kill "$pid" 2>/dev/null || true
  pkill -P "$pid" 2>/dev/null || true
  pgrep -f "^$out/soc/gateware/obj_dir/Vsim" >/dev/null 2>&1 && pkill -f "^$out/soc/gateware/obj_dir/Vsim" || true
  wait "$pid" 2>/dev/null || true
  exec 3>&-
  strip_ansi "$log" | sed -n '/Booting from serial\|Executing booted program\|LiteX minimal demo/,$p' | grep -vE '^\s*$' | sed -n 1,30p
  return "$rc"
}
case "$act" in
  build) build ;;
  run)   build; boot ;;
  test)  build; boot | tee "$out/run.log"; grep -q 'Liftoff' "$out/run.log"; grep -q 'C: Hello, world' "$out/run.log"
         echo "PASS litex_sim_firmware (demo app booted from main RAM, helloc ran)" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

# shellcheck shell=bash disable=SC2015,SC2034  # d_* return 0; TOOL_* are read by boxtool.bash
# fpga-box: tool part (hooks for lib/boxtool.bash). Everything comes from the pixi env:
# conda-forge Yosys/Verilator/Icarus/GTKWave/gcc + RISC-V cross gcc, YoWASP nextpnr + pack
# tools (PyPI, WebAssembly), LiteX/Migen pinned to the 2026.08 release.
TOOL_TITLE="32_09_fpga: Yosys + nextpnr (YoWASP) + Verilator + Icarus + LiteX 2026.08"
TOOL_INSTALL_WHAT="the example builds (examples build)"
TOOL_HELP_USE="  tools                   versions of every HDL tool in the env
  sim <top.v> [tb.cpp]    quick Verilator build+run (--binary for a SV testbench, else C++ tb)
  litex-sim [args]        litex_sim (LiteX SoC simulated with Verilator; e.g. --cpu-type vexriscv)
  wave <file.vcd>         open a waveform in GTKWave (needs a display)"
hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$BOXT_NAME tools                            versions of every HDL tool
  ./$BOXT_NAME sim counter.v tb.cpp             Verilator build + run with a C++ testbench
  ./$BOXT_NAME litex-sim --cpu-type vexriscv    LiteX SoC on Verilator
  ./$BOXT_NAME wave dump.vcd                    GTKWave (needs a display)
tool environment
  everything comes from the pixi env (CONDA_PREFIX); no extra variables
EOF
}
# shellcheck source-path=SCRIPTDIR source=boxtool.bash
. "$BOXT_ROOT/lib/boxtool.bash"

SHIMS="$ROOT/cache/shims"
# YoWASP commands get their usual names; the conda RISC-V cross gcc gets a triple LiteX
# looks for (riscv64-linux-gnu-*). Written on activation, inside this folder only.
write_shims() {
  [ -d "$ENV_DIR/bin" ] || return 0
  [ -e "$SHIMS/.v2" ] && return 0
  mkdir -p "$SHIMS"
  local t n
  for t in nextpnr-ice40 nextpnr-ecp5 icepack iceunpack icebram icemulti icepll ecppack ecpunpack ecpbram ecpmulti ecppll; do
    printf '#!/bin/sh\nexec yowasp-%s "$@"\n' "$t" >"$SHIMS/$t"; chmod +x "$SHIMS/$t"
  done
  for t in "$ENV_DIR"/bin/riscv64-conda-linux-gnu-*; do
    n=$(basename "$t"); n=riscv64-linux-gnu-${n#riscv64-conda-linux-gnu-}
    printf '#!/bin/sh\nexec %s "$@"\n' "$(basename "$t")" >"$SHIMS/$n"; chmod +x "$SHIMS/$n"
  done
  : >"$SHIMS/.v2"
}

hook_env() {
  write_shims
  export PATH="$SHIMS:$PATH"
  export AMARANTH_USE_YOSYS=system                 # Amaranth runs the env's yosys (not the amaranth-yosys wheel)
  export YOWASP_CACHE_DIR="$ROOT/cache/yowasp"     # compiled WebAssembly (else ~/.cache/YoWASP)
  export CCACHE_DIR="$ROOT/cache/ccache"
  export MAKEFLAGS="-j$JOBS"
  export FPGA_BOX_ROOT="$ROOT"
  # Two compiler activations run (host gcc and the RISC-V cross gcc); the cross one wins and
  # leaves CC/CFLAGS for riscv64. Reset them to the host compiler: Verilator models and the
  # litex_sim core are host code; LiteX calls riscv64-linux-gnu-gcc by name for the BIOS.
  # json-c, libevent, zlib come from the env (not /usr).
  if [ -n "${CONDA_PREFIX:-}" ]; then
    unset CPPFLAGS DEBUG_CFLAGS DEBUG_CXXFLAGS
    export CC=x86_64-conda-linux-gnu-gcc CXX=x86_64-conda-linux-gnu-g++
    command -v "$CC" >/dev/null 2>&1 || { CC=gcc; CXX=g++; }
    export CFLAGS="-I$CONDA_PREFIX/include" CXXFLAGS="-I$CONDA_PREFIX/include"
    export LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath,$CONDA_PREFIX/lib"
  fi
}

hook_bootstrap() { cachedir_tag "$ROOT/cache"; }
hook_relocate() { [ -d "$SHIMS" ] && trash_paths "relocate: shims point at old env" "$SHIMS"; return 0; }

hook_install() {
  info "warming the YoWASP cache (first nextpnr run compiles WebAssembly, ~1 min)"
  activate
  run yowasp-nextpnr-ice40 --version >/dev/null 2>&1 || true
  run yowasp-nextpnr-ecp5 --version >/dev/null 2>&1 || true
  cmd_examples build
}

hook_status() {
  local e n=0
  for e in $(ex_list); do [ -d "$BUILD/examples/$e" ] && n=$((n+1)); done
  printf '  %-22s %s of %s built in %s\n' examples "$n" "$(ex_list | wc -l)" "$BUILD/examples"
}

tool_versions() {
  printf '  %-16s %s\n' yosys "$(yosys -V 2>/dev/null | cut -d' ' -f2)"
  printf '  %-16s %s\n' verilator "$(verilator --version 2>/dev/null | cut -d' ' -f2)"
  printf '  %-16s %s\n' iverilog "$(iverilog -V 2>/dev/null | head -1 | sed 's/Icarus Verilog version //')"
  printf '  %-16s %s\n' nextpnr-ice40 "$(nextpnr-ice40 --version 2>&1 | grep -o 'nextpnr-[0-9][0-9.]*' | head -1)"
  printf '  %-16s %s\n' nextpnr-ecp5 "$(nextpnr-ecp5 --version 2>&1 | grep -o 'nextpnr-[0-9][0-9.]*' | head -1)"
  printf '  %-16s %s\n' gtkwave "$(gtkwave --version 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -1)"
  printf '  %-16s %s\n' riscv-gcc "$(riscv64-linux-gnu-gcc -dumpversion 2>/dev/null)"
  printf '  %-16s %s\n' litex "$(python -c 'import importlib.metadata as m; print(m.version("litex"))' 2>/dev/null)"
}

hook_doctor() {
  local v
  v=$(yosys -V 2>/dev/null | cut -d' ' -f2) && d_ok "yosys $v" || d_fail "yosys missing"
  v=$(verilator --version 2>/dev/null | cut -d' ' -f2) && d_ok "verilator $v" || d_fail "verilator missing"
  v=$(iverilog -V 2>/dev/null | head -1 | sed 's/Icarus Verilog version //') && d_ok "iverilog $v" || d_fail "iverilog missing"
  v=$(nextpnr-ice40 --version 2>&1 | grep -o 'nextpnr-[0-9][0-9.]*' | head -1) && [ -n "$v" ] && d_ok "nextpnr-ice40 $v (YoWASP)" || d_fail "nextpnr-ice40 (YoWASP) not working"
  v=$(nextpnr-ecp5 --version 2>&1 | grep -o 'nextpnr-[0-9][0-9.]*' | head -1) && [ -n "$v" ] && d_ok "nextpnr-ecp5 $v (YoWASP)" || d_fail "nextpnr-ecp5 (YoWASP) not working"
  command -v icepack >/dev/null && command -v ecppack >/dev/null && d_ok "icepack/ecppack (YoWASP)" || d_fail "icepack/ecppack missing"
  command -v gtkwave >/dev/null && d_ok "gtkwave present" || d_warn "gtkwave missing"
  v=$(riscv64-linux-gnu-gcc -dumpversion 2>/dev/null) && d_ok "riscv64 gcc $v (LiteX BIOS)" || d_fail "riscv64-linux-gnu-gcc shim missing"
  v=$(g++ -dumpversion 2>/dev/null) && d_ok "host g++ $v (Verilator models)" || d_fail "host g++ missing"
  v=$(python -c 'import importlib.metadata as m, litex, migen, litex_boards; print(m.version("litex"))' 2>/dev/null) && d_ok "litex $v + migen + litex-boards" || d_fail "litex import failed"
  v=$(z3 --version 2>/dev/null | awk '{print $3}') && [ -n "$v" ] && command -v yosys-smtbmc >/dev/null && d_ok "z3 $v + yosys-smtbmc (formal)" || d_fail "z3 / yosys-smtbmc missing"
  python -c 'import cocotb_tools.runner' 2>/dev/null && d_ok "cocotb runner (Icarus, Verilator)" || d_fail "cocotb missing"
  v=$(python -c 'import amaranth; print(amaranth.__version__)' 2>/dev/null) && d_ok "amaranth $v" || d_fail "amaranth missing"
  [ -d "$ROOT/cache/yowasp" ] && d_ok "YoWASP cache inside the folder" || d_warn "YoWASP cache not warmed yet (./$NAME install)"
}

hook_native_bins() {
  local t
  for t in yosys yosys-config iverilog vvp gtkwave; do echo "$t .pixi/envs/default/bin/$t"; done
  for t in verilator verilator_coverage nextpnr-ice40 nextpnr-ecp5 icepack ecppack litex_sim; do echo "$t @run $t"; done   # verilator needs the env g++/perl
}

tool_cmd_tools() { activate; tool_versions; }
tool_cmd_sim() {
  [ $# -ge 1 ] || usage_error "usage: ./$NAME sim <top.v|sv> [tb.cpp]"
  local top=$1 tb=${2:-} od mod
  activate
  mod=$(basename "${top%.*}"); od="$BUILD/sim/$mod"
  if [ -n "$tb" ]; then run verilator --cc --exe --build -j "$JOBS" --trace -Mdir "$od" "$top" "$tb"
  else run verilator --binary -j "$JOBS" --trace -Mdir "$od" "$top"; fi
  run "$od/V$mod"
}
tool_cmd_litex-sim() { activate; [ "$DRY" = 1 ] && { printf '+ litex_sim %s\n' "$*"; return 0; }; mkdir -p "$BUILD/litex_sim"; cd "$BUILD/litex_sim" && exec litex_sim "$@"; }
tool_cmd_wave() { activate; [ "$DRY" = 1 ] && { printf '+ gtkwave %s\n' "$*"; return 0; }; exec gtkwave "$@"; }

boxt_main "$@"

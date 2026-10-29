# 32_09_fpga notes

## 2026-10-24/25 created
- Built in the 32_06_renode launcher pattern: `fpga-box` (pinned pixi 0.81.0) + `lib/boxtool.bash` (own copy) + `lib/fpga.bash`.
- No FPGA boards owned, so the ID is simulation- and synthesis-check-oriented. OSS CAD Suite (748 MB tgz, nightly only) rejected in favour of a locked pixi env.
- `litex-hub` conda channel: prjtrellis/nextpnr need libboost 1.73 → unsolvable. Switched nextpnr + icepack/ecppack to YoWASP (PyPI, WebAssembly). Set `YOWASP_CACHE_DIR=cache/yowasp`; the first run had already written `~/.cache/YoWASP` (8.6 MB) → trashed (logged).
- litex_sim needed liteeth, litedram, litescope, pythondata-misc-tapcfg, and json-c + libevent from conda-forge.
- RISC-V BIOS builds with conda-forge `riscv64-conda-linux-gnu-gcc` 15.3 via `riscv64-linux-gnu-*` shims. No xPack toolchain needed.
- Pitfalls fixed: the cross-gcc activation overrides CC/CFLAGS (→ x86 link of riscv objects). The conda activation exports `BUILD=<triple>`, which clobbered boxtool's `$BUILD` (fixed in `activate()`). The BIOS console uses `\r\n` and ANSI colours (strip both before grepping). `grep -q` in a pipe under pipefail → SIGPIPE false negatives (use `grep -c`).
- `--ident` cannot be passed to litex_sim (it sets ident itself), so `ident` prints `-`. The test only checks that the command answers.
- Results: install ok, doctor 16 ok / 0 warn / 0 fail, examples test 5/5 ok, tests/test_dry_run.sh 25/25 (incl. shellcheck), tests/test_smoke.sh 7/7, both templates built.
- Size: .pixi 3.3 GB + 0.8 GB unique pixi cache (above the ~2 GB guideline; host + cross GCC are ~2 GB of it).

## 2026-10-25: readability pass 2 (script_style.md, scripts/README)
- lib/boxtool.bash (reference `00_09_meta/05_policy/templates/tool/lib/boxtool.bash`, synced to all 24 copies):
  `where`/`status`/`doctor`/`bootstrap`/`relocate` reject extra arguments (exit 2); colour only on a terminal
  and never with `NO_COLOR`; help lists `NO_COLOR`.
- `help` now ends with `tool examples` / `tool environment` (hook_help in lib/fpga.bash).
- README: exit codes, `BOX_INTEGRATION` and `NO_COLOR` rows. Backups:
  `00_09_meta/02_logs/config_backups/2026_10_25_readability2_embedded_tools/`.

## 2026-10-29: 14 examples, 11 templates, git repo
- pixi env (additive re-solve, nothing else moved): cocotb 2.1.0 + z3-solver 5.1.0 (conda-forge), amaranth 0.5.10 (PyPI),
  litespi 2026.08 (git, needed by the litex-boards iCEBreaker target). Launcher sets `AMARANTH_USE_YOSYS=system`.
  doctor checks z3/yosys-smtbmc, cocotb and amaranth (19 checks).
- SymbiYosys not added: fetching and running its source tarball was not permitted in this session. The formal examples
  and the `formal_props` template call `yosys-smtbmc` + z3 directly (what `sby` drives).
- Shared RTL in `examples/common/rtl/` (uart_tx/rx, sync_fifo with formal properties, debounce, pwm, spi_master);
  `W'(x)` casts need `read_verilog -sv` in yosys.
- New examples: uart_rx_icarus, uart_loopback_cocotb, debounce_cocotb_verilator, spi_master_verilator, pwm_sv_verilator,
  fifo_formal, equiv_check_yosys, verilator_coverage, amaranth_ice40, ice40_pll_uart, ice40_bram_swap, synth_compare,
  litex_sim_firmware, litex_icebreaker_soc. Board examples build bitstreams only (no board, nothing flashed).
- New templates: icarus_tb, sv_testbench, cocotb_test, formal_props, ecp5_project, amaranth_module, uart_ip,
  equiv_check, litex_soc, coverage_tb, ice40_pll_project. `tests/test_smoke.sh` now creates every template and runs
  its make target, and fails if a template kind is not covered.
- Problems found:
  - YoWASP nextpnr has no Python: LiteX's own iCE40 run (`--pre-pack` script) fails with "unrecognised option".
    LiteX now only exports (`--no-compile-gateware`) and the example/template run nextpnr with `--freq`.
  - VexRiscv minimal on the UP5K reaches 22.8 MHz: 24 MHz failed timing, the SoC runs at 16 MHz.
  - `icepll -m` makes an SB_PLL40_CORE, which cannot share pin 35 with the clock input: `-p` (pad PLL) is needed.
  - Icarus has no `@(... iff ...)` and warned on queue `==`: loops instead.
  - `verilator_coverage --annotate` writes only files with missed points unless `--annotate-all`; the lcov file has
    no LF/LH lines (counted from DA lines). The litex_sim_firmware check first matched the help text ("Hello C").
  - A stray `examples/x86_64-conda-linux-gnu/` (empty dirs from the old `BUILD` clobber) was moved to the Trash (logged).
- Results: doctor 19 ok / 0 warn / 0 fail; examples 19/19; test_smoke.sh 24/24 (13 templates); test_dry_run.sh 25/25
  (shellcheck clean); `box scripts check 32_09` clean.

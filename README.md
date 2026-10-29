# 32_09_fpga - FPGA / HDL tools (simulate, synthesise, LiteX)

The open FPGA flow in one folder: simulation (Verilator, Icarus Verilog, GTKWave), synthesis (Yosys), place and route plus
bitstream packing for iCE40 and ECP5 (nextpnr, icepack, ecppack), and the LiteX SoC builder with a VexRiscv BIOS that boots
under Verilator. Use it to simulate HDL, check that a design synthesises and meets timing, and run LiteX SoCs, which can
also feed Renode (`32_06_renode`). One pinned pixi env; no sudo, no system packages; caches stay in the folder.

**Boards.** You own no FPGA board (`32_01_mcu/tool/BOARDS.md` lists none). The flows target common dev boards so a board bought
later works at once. Programming a board (iceprog, openFPGALoader) is **not** included: it needs udev rules and a device.

| Family | Example board in this ID | Others the same flow covers |
|---|---|---|
| iCE40 UP5K/HX/LP | iCEBreaker (UP5K-SG48) | UPduino 3, iCESugar, TinyFPGA BX, iCE40-HX8K-EVB, Fomu |
| ECP5 | ULX3S (LFE5U-85F) | OrangeCrab, Colorlight i5/i9, ECP5-EVN, ButterStick |
| any, via LiteX | `litex_sim` (no hardware) | every board in `litex-boards` (Gowin/Xilinx need vendor or extra tools, not included) |

Status: **ready** (doctor 19 ok, examples 19/19, templates 13/13, 2026-10-29). Launcher: `./fpga-box`.

## What's included

| Tool | Version | Source |
|---|---|---|
| Yosys | 0.69 | conda-forge |
| Verilator | 5.052 | conda-forge |
| Icarus Verilog | 13.0 | conda-forge |
| GTKWave | 3.3.121 | conda-forge |
| nextpnr-ice40 / nextpnr-ecp5 (+ icepack, icebram, icepll, ecppack, ecpunpack, ecppll ...) | nextpnr 0.11.1 (`yowasp-nextpnr-* 0.11.1.0.post826`) | PyPI [YoWASP](https://yowasp.org/) (WebAssembly, runs via wasmtime 47) |
| LiteX / litex-boards | 2026.08 (`b6ae9e0`, `e430792`) | git enjoy-digital/litex, litex-hub/litex-boards |
| liteeth / litedram / litescope | 2026.08 | git enjoy-digital (needed by `litex_sim`) |
| Migen | 0.9.2+ (`e19524c`, master) | git m-labs/migen |
| pythondata-cpu-vexriscv, -software-picolibc, -software-compiler_rt | 2026.08 | git litex-hub |
| pythondata-misc-tapcfg | master `a12c3f5` | git litex-hub (no 2026.08 tag) |
| RISC-V GCC (LiteX BIOS) | 15.3.0 `riscv64-conda-linux-gnu` | conda-forge `gcc_linux-riscv64` |
| host gcc/g++ (Verilator models, litex_sim core) | 15.3.0 | conda-forge `cxx-compiler` |
| cocotb | 2.1.0 | conda-forge (Python testbenches on Icarus and Verilator, `cocotb_tools.runner`) |
| z3 + yosys-smtbmc | 5.1.0 + Yosys 0.69 | conda-forge (formal: BMC, k-induction, cover) |
| Amaranth HDL | 0.5.10 | PyPI (uses the env's yosys: `AMARANTH_USE_YOSYS=system`) |
| litespi | 2026.08 | git litex-hub (SPI flash for litex-boards targets such as the iCEBreaker) |
| Python / pixi | 3.12.15 / 0.81.0 | conda-forge / sha256-pinned in `fpga-box` |

Why this set (not the OSS CAD Suite, YoWASP for nextpnr, shimmed RISC-V compiler): [docs/design_decisions.md](docs/design_decisions.md).

## Quick start

```sh
cd "$BOX_FPGA"                                  # or: cd $BOX/30_39_tools/32_embedded/32_09_fpga
./fpga-box install && ./fpga-box doctor         # env (about 6 min cold) + YoWASP warm-up + example builds; 19 checks
./fpga-box examples test                        # 19 examples, about 3 min warm (litex_sim cold: several minutes of Verilator)
./fpga-box new verilator_module accum           # a module + C++ testbench + Makefile (then `make run` / `make wave` inside it)
./fpga-box sim top.sv                           # or a quick Verilator --binary build + run of your own file
```

With the Box shell set up once (`box shell install --apply`), the `fpga-box` shim works from any folder,
and `box test|doctor|status fpga` run this launcher (`box clean fpga` is a dry run until `--apply`).
Standalone (no Box, or `BOX_INTEGRATION=0`), `./fpga-box` keeps its output in this folder.

## Commands

Global option: `--dry-run` / `-n` prints what a command would do. Exit codes: 0 ok, 1 failure, 2 usage error (unknown command or option, or arguments given to `where`, `status`, `doctor`, `bootstrap` or `relocate`), 3 not applicable. `help` ends with this tool's own examples and variables (`tool examples`, `tool environment`).

| Command | What it does | Example |
|---|---|---|
| `bootstrap` | pinned pixi + env + core downloads | `./fpga-box bootstrap` |
| `install [--no-demos]` | bootstrap + demo downloads | `./fpga-box install` |
| `update [--check\|--env]` | `--check` (default): pins vs newest upstream; `--env`: re-solve pixi env | `./fpga-box update --check` |
| `clean [--all] [--yes]` | move build/log output (`--all`: also install/, .pixi, native/, downloads) to the Trash; dry run unless `--yes` | `./fpga-box --dry-run clean --all` |
| `status`, `where`, `doctor` | versions and sizes, paths, health checks (exit 1 on failure) | `./fpga-box doctor` |
| `shell [-- cmd ...]` | bash (or a command) with every tool on PATH | `./fpga-box shell` |
| `run <cmd> [args]` | one command inside the environment | `./fpga-box run yosys -V` |
| `tools` | versions of every HDL tool in the env | `./fpga-box tools` |
| `sim <top.v> [tb.cpp]` | quick Verilator build + run (`--binary` for a SystemVerilog testbench, else C++ testbench) | `./fpga-box sim top.sv` |
| `litex-sim [args]` | `litex_sim`: a LiteX SoC simulated with Verilator | `./fpga-box litex-sim --cpu-type vexriscv` |
| `wave <file.vcd>` | open a waveform in GTKWave (needs a display) | `./fpga-box wave x.vcd` |
| `test [--all]` | `tests/test_smoke.sh`; `--all` adds dry-run and examples tests | `./fpga-box test` |
| `new <kind> <name> [--dir D] [--force]` | from `templates/` (13 kinds, see below) | `./fpga-box new ice40_project blink` |
| `examples list \| run <ex> [args] \| build [ex...] \| test [ex...]` | list, run, build or test examples | `./fpga-box examples run ice40_blinky` |
| `native [--print]` | write `native/{native.zsh,native.bash,bin/}` | `./fpga-box native` |
| `relocate` | after moving the folder: re-create the env, rewrite `native/` | `./fpga-box relocate` |
| `pack [--with-cache] [--out F]` | tarball of this folder for another machine | `./fpga-box pack` |
| `help`, `-h`, `--help` | command list | `./fpga-box help` |

## Examples and templates

`examples/<name>/example.sh build|run|test`; output in `$BOX_V3/30_39_tools/32_embedded/32_09_fpga/build/examples/<name>/`.

| Example | What it checks | Result 2026-10-25 |
|---|---|---|
| `verilator_uart_tx` | 8N1 UART TX in Verilog + Verilator C++ testbench with a line decoder, compares 16 bytes, VCD | ok (1 s) |
| `icarus_counter` | 4-bit counter, Icarus testbench: count, enable, clear, wrap, `$fatal` on error, VCD | ok |
| `ice40_blinky` | iCEBreaker: synth_ice40, nextpnr-ice40 (UP5K, `.pcf`), icepack 104 KB `.bin`; Fmax 74.8 MHz vs 12 required | ok (2 s) |
| `ecp5_blinky` | ULX3S 85F: synth_ecp5, nextpnr-ecp5 (`.lpf`), ecppack `.bit`; Fmax 286 MHz vs 25 required | ok (3 s) |
| `litex_sim_vexriscv` | LiteX SoC (VexRiscv, 64 KiB RAM) under Verilator: BIOS banner, memtest, `litex>` prompt, `ident`; exports `csr.csv`/`csr.json` and a Renode `litex_sim.repl/.resc` | ok (15 s warm, about 4 min cold) |
| `uart_rx_icarus` | 8N1 UART receiver (`common/rtl/uart_rx.v`), Icarus SV testbench: 6 bytes, a glitch ignored, a framing error flagged, VCD | ok 2026-10-29 |
| `uart_loopback_cocotb` | cocotb 2.1 on Icarus: UART TX -> RX loopback, 64 random bytes through a Python monitor, bit-level driver injects a bad stop bit | ok |
| `debounce_cocotb_verilator` | cocotb 2.1 on Verilator: push-button debouncer, random contact bounce, one rise/fall per press, latency N+2, spikes ignored | ok |
| `spi_master_verilator` | SPI master (`common/rtl/spi_master.v`) in all 4 modes against a behavioural C++ slave: full-duplex bytes, 16 edges, CS framing | ok |
| `pwm_sv_verilator` | SystemVerilog testbench on `verilator --binary --timing`: PWM duty measured per period, glitch-free mid-period update, a concurrent assertion | ok |
| `fifo_formal` | no testbench: FIFO properties proven by yosys-smtbmc + z3 (BMC 20, k-induction, cover); a seeded overwrite bug gives a counterexample VCD | ok |
| `equiv_check_yosys` | formal equivalence: adder-tree popcount and a Gray-only counter equal to reference RTL (`equiv_make/simple/induct`); seeded bug caught | ok |
| `verilator_coverage` | `--coverage-line/-toggle` on the uart_rx testbench: `coverage.dat`, annotated source, lcov file, line coverage >= 90 % (100 %) | ok |
| `amaranth_ice40` | Amaranth HDL (Python): breathing-LED PWM simulated in Python, exported to Verilog, iCEBreaker bitstream, Fmax 78 MHz | ok |
| `ice40_pll_uart` | `icepll -p` 48 MHz pad PLL + UART TX at 115200 on the iCEBreaker FTDI pin; `SB_PLL40_PAD` in the netlist, Fmax 56 MHz >= 48 | ok (build only) |
| `ice40_bram_swap` | `icebram`: new BRAM contents in a finished bitstream in about 0.4 s (no synthesis or P&R); diff shows only `.ram_data` changed | ok |
| `synth_compare` | one RTL block (UART, SPI, FIFO, PWM) through `synth_ice40`, `synth_ecp5`, `synth_gowin`, `synth_xilinx`, generic: LUT/FF/carry/RAM table, no latches | ok |
| `litex_sim_firmware` | own firmware on a LiteX SoC: `litex_bare_metal_demo` built against the litex_sim headers, loaded with `--ram-init`, BIOS boots it, `helloc` runs | ok (15 s warm) |
| `litex_icebreaker_soc` | LiteX SoC for a real board (litex-boards iCEBreaker, VexRiscv minimal at 16 MHz): export + BIOS, then yosys/nextpnr-ice40/icepack; 3744/5280 LCs, Fmax 22.8 MHz | ok (build only, 40 s) |

Templates (`./fpga-box new <kind> <name> [--dir D]`; each instance builds with `fpga-box shell -- make <target>`, and
`tests/test_smoke.sh` creates and runs all 13):

| Kind | What you get | Check target |
|---|---|---|
| `verilator_module` | module + C++ testbench with a reference model, VCD | `make run` |
| `ice40_project` | iCEBreaker top, `.pcf`, yosys/nextpnr/icepack Makefile | `make` |
| `ice40_pll_project` | iCEBreaker top with an `icepll -p` PLL (`FREQ_OUT`), timing checked at that frequency | `make test` |
| `ecp5_project` | ULX3S (85F) top, `.lpf` (LEDs, buttons, clock), nextpnr-ecp5/ecppack, Fmax check | `make test` |
| `icarus_tb` | module + self-checking Icarus SV testbench (random stimulus, model, `$fatal`) | `make test` |
| `sv_testbench` | valid/ready module + Verilator `--binary` SV testbench (scoreboard queue, concurrent assertion) | `make test` |
| `cocotb_test` | module + cocotb 2.1 tests + `run.py` (Python runner) for Icarus and Verilator, JUnit results | `make test-all` |
| `formal_props` | arbiter with `assume/assert/cover`, yosys-smtbmc + z3 BMC, induction, cover | `make prove` |
| `equiv_check` | gold/gate pair, `equiv.ys` (equiv_*) and `miter.ys` (miter + SAT) | `make test` |
| `coverage_tb` | FSM + SV testbench with `cover property`, Verilator coverage, annotated source, lcov, minimum % | `make cover` |
| `uart_ip` | parameterised UART TX/RX IP + loopback testbench (Icarus and Verilator), lint, synth | `make test` |
| `amaranth_module` | Amaranth `wiring.Component`, async testbench, Verilog export, iCE40 synthesis | `make test` |
| `litex_soc` | litex-boards iCEBreaker SoC + an own CSR peripheral (PWM); export, BIOS, bitstream | `make test` / `make bitstream` |

LiteX SoC in Renode: `$BOX_RENODE/renode-box renode build/examples/litex_sim_vexriscv/renode/litex_sim.resc` (run from the
`$BOX_V3/.../32_09_fpga/` build folder). The `.resc` was generated and syntax-checked here but **not yet run in Renode**.

## Configuration and environment variables

| Variable | Default | Meaning |
|---|---|---|
| `BOXT_OUT` | same ID path on idisk03, else here | output root (`build/`, `log/`); or `config/local.env` |
| `BOXT_JOBS` | 8 (maximum 8) | parallel jobs |
| `BOXT_MIN_FREE_GB` / `BOXT_RAM_WAIT_MAX` | 8 / 3600 | pause builds below this free RAM (GB) / give up after s |
| `BOXT_NET_TIMEOUT` | 3600 | seconds for one download |
| `BOXT_PLATFORM` | detected (`linux-x64`) | override platform |
| `GITHUB_TOKEN` | unset | optional, lifts the API limit for `update --check` |
| `BOX_INTEGRATION` | 1 | `0` = standalone: ignore `$BOX`/`$BOX_V3`, keep output in this folder |
| `NO_COLOR` | unset | set to print plain text (colour is only used on a terminal anyway) |
| `YOWASP_CACHE_DIR` | `cache/yowasp` (set by the launcher) | compiled WebAssembly cache; never `~/.cache/YoWASP` |
| `BOX_FPGA` | set by `box_env.sh` | path of this ID, used by the native snippet |
| `BOX_NATIVE_OFF_FPGA` | unset | `1` skips native mode for one shell (old name `FPGABOX_NATIVE_OFF` still honoured) |

The launcher resets `CC`/`CXX`/`CFLAGS`/`LDFLAGS` to the host compiler plus the env's json-c/libevent/zlib, because the host and
cross compiler activations conflict.

## Where files go

| What | Where |
|---|---|
| Source, launcher, examples, templates | this ID |
| Env | `.pixi/` 3.3 GB (host gcc + sysroot about 1 GB, RISC-V cross gcc about 1 GB, YoWASP nextpnr 390 MB, Python + LiteX data 300 MB); `.bin/` 110 MB |
| Cache | `cache/pixi` (+0.8 GB beyond the env, rest hardlinked), `cache/yowasp` + `cache/shims` (26 MB: compiled WebAssembly, command shims) |
| Build output and logs | `$BOX_V3/30_39_tools/32_embedded/32_09_fpga/{build,log}` (282 MB build) |

About 4.1 GB on idisk01, above the 2 GB guideline; the two GCCs are most of it. Dropping `cache/pixi` saves 0.8 GB at the cost of a
re-download on the next `install`. `clean` only moves files to the Trash (logged) and is a dry run without `--yes`.

## Native mode

`./fpga-box native` writes `native/native.{zsh,bash}` and `native/bin/`. `yosys`, `yosys-config`, `iverilog`, `vvp`
and `gtkwave` run straight from the env; `verilator`, `verilator_coverage`, `nextpnr-ice40`, `nextpnr-ecp5`,
`icepack`, `ecppack` and `litex_sim` go through `fpga-box run` (they need the env's g++/perl/python). Nothing else
goes on PATH; paths are relative. Load it in every shell (zsh, bash, fish) with `box native enable fpga --apply`: it
runs `./fpga-box native` when the files are missing and rebuilds `box_env.d/native.*` (without `--apply` it only shows
the plan; `box native disable fpga --apply` undoes it). `BOX_NATIVE_OFF_FPGA=1` skips it for one shell (the old
`FPGABOX_NATIVE_OFF` still works for now). Without Box, source `native/native.zsh` or `native/native.bash` from your
shell rc.

## Tests

```sh
./fpga-box test --all
tests/test_dry_run.sh      # every command in dry-run + shellcheck (25 checks)
tests/test_smoke.sh        # each tool does one small real job + every template created and run (24 checks)
```

Last known (2026-10-29): doctor 19 ok / 0 warn / 0 fail; `examples test` 19/19; `test_dry_run.sh` 25/25 (shellcheck clean);
`test_smoke.sh` 24/24 (13 templates created and run).

## Troubleshooting

| Symptom | Fix |
|---|---|
| First nextpnr/icepack call takes about 1 min | YoWASP compiles its WebAssembly once; cached in `cache/yowasp` |
| LiteX BIOS link errors (x86 link of riscv objects) | the cross-gcc activation overrides `CC`/`CFLAGS`; use `fpga-box` (it resets them), not a bare env shell |
| Grepping the BIOS console finds nothing | the console prints `\r\n` and ANSI colours: strip both first |
| `grep -q` in a pipe gives false negatives | SIGPIPE under `pipefail`: use `grep -c` |
| `--ident` rejected by `litex_sim` | it sets ident itself, so `ident` prints `-`; the test only checks that the command answers |
| `litex-hub` conda channel packages do not solve | needs boost 1.73; use the YoWASP route already in place |
| `wave` does nothing | GTKWave needs a display |

## Limitations / needs you

- No FPGA board and no programmer: nothing here flashes hardware. If you buy a board, add openFPGALoader or iceprog plus udev rules.
- `linux-64` only in `pixi.toml`. macOS: add platforms and run `update --env`. Windows: Yosys, Icarus and YoWASP work, but the `litex_sim`
  core needs a POSIX toolchain (use WSL).
- Gowin/Xilinx place and route is not included (`synth_compare` only synthesises for them). SymbiYosys (`sby`) is not
  bundled: the formal examples call `yosys-smtbmc` + z3 directly, the same flow `sby` drives.
- LiteX `.resc` for Renode is not yet run in Renode. No sudo or licence needed; no entry in `2026_10_25_open_items.md`.

## Scripts

Each script has a `[scripts.*]` descriptor in `.box.toml` (`box scripts show 32_09`; `box scripts check 32_09` must stay clean).

- `examples/ecp5_blinky/example.sh`: ECP5 flow for ULX3S (LFE5U-85F): yosys synth_ecp5 -> nextpnr-ecp5 -> ecppack bitstream + Fmax check
- `examples/icarus_counter/example.sh`: Icarus Verilog testbench: 4-bit counter (enable, clear, wrap) with self-checks + VCD
- `examples/ice40_blinky/example.sh`: iCE40 flow for iCEBreaker (UP5K): yosys synth_ice40 -> nextpnr-ice40 -> icepack bitstream + Fmax check
- `examples/litex_sim_vexriscv/example.sh`: LiteX SoC (VexRiscv, 2026.08) simulated by Verilator: BIOS boots to litex>, runs `ident`; exports csr.json + Renode .repl/.resc
- `examples/verilator_uart_tx/example.sh`: Verilator C++ testbench: 8N1 UART transmitter, line decoder + byte assertions, VCD
- `examples/uart_rx_icarus/example.sh`: Icarus Verilog: 8N1 UART receiver (synchroniser, mid-bit sampling) - 6 bytes, glitch rejected, framing error flagged
- `examples/uart_loopback_cocotb/example.sh`: cocotb 2.1 + Icarus: UART TX->RX loopback, 64 random bytes via a Python monitor, bit-level driver injects a framing error
- `examples/debounce_cocotb_verilator/example.sh`: cocotb 2.1 + Verilator: push-button debouncer, random contact bounce, one rise/fall per press, latency and glitch checks
- `examples/spi_master_verilator/example.sh`: Verilator C++ testbench: SPI master in all 4 modes (CPOL/CPHA) against a behavioural slave, full-duplex bytes, edge count, CS framing, VCD
- `examples/pwm_sv_verilator/example.sh`: SystemVerilog testbench on Verilator --binary (timing, concurrent assertion): PWM duty measured per period, glitch-free mid-period update
- `examples/fifo_formal/example.sh`: formal verification without a testbench: sync FIFO properties proven by yosys-smtbmc + z3 (BMC, k-induction, cover); a seeded bug must fail with a counterexample VCD
- `examples/equiv_check_yosys/example.sh`: Yosys formal equivalence: adder-tree popcount and a Gray-only counter proven equal to reference RTL (equiv_make/simple/induct); a seeded bug is caught
- `examples/verilator_coverage/example.sh`: Verilator --coverage (line + toggle) on the uart_rx testbench: coverage.dat, verilator_coverage annotated source, line coverage >= 90 %
- `examples/amaranth_ice40/example.sh`: Amaranth HDL 0.5 (Python): breathing-LED PWM simulated in Python, exported to Verilog, built for iCEBreaker (yosys, nextpnr-ice40, icepack)
- `examples/ice40_pll_uart/example.sh`: iCE40 PLL + UART: icepll makes a 48 MHz pad PLL from 12 MHz, UART TX at 115200 on iCEBreaker; checks SB_PLL40_PAD in the netlist and Fmax >= 48 MHz (no board: build only)
- `examples/ice40_bram_swap/example.sh`: icebram: swap the block-RAM contents of a finished iCE40 bitstream (no re-synthesis or P&R); diff proves only BRAM init changed
- `examples/synth_compare/example.sh`: one RTL block (UART, SPI, FIFO, PWM) synthesised by yosys for iCE40, ECP5, Gowin, Xilinx 7 and generic gates: LUT/FF/carry/RAM table, no latches (synthesis only)
- `examples/litex_sim_firmware/example.sh`: own C firmware on a LiteX SoC: headers from litex_sim, litex_bare_metal_demo built with the RISC-V gcc, loaded with --ram-init, BIOS boots it, its shell runs `helloc` (Verilator; first run several minutes)
- `examples/litex_icebreaker_soc/example.sh`: LiteX SoC for a real board (iCEBreaker, litex-boards): VexRiscv + BIOS, LiteX exports gateware + builds the BIOS, then yosys/nextpnr-ice40/icepack; checks utilisation and 16 MHz timing (no board: build only)
- `examples/common/rtl/`: shared RTL of the examples (UART TX/RX, FIFO with formal properties, debouncer, PWM, SPI master)
- `fpga-box`: the launcher (POSIX sh): bootstraps the pinned pixi, keeps caches inside this folder, then runs lib/; `./fpga-box help` lists the commands
- `lib/boxtool.bash`: shared launcher framework (boxtool 3: bootstrap, pinned downloads, pixi env, every common command); byte-identical copy of `$BOX/00_09_meta/05_policy/templates/tool/lib/boxtool.bash` (edit there, then sync)
- `lib/fpga.bash`: this tool's part of the launcher: TOOL_* settings, hook_* functions and extra commands (`./fpga-box help`)
- `tests/test_dry_run.sh`: every launcher command in --dry-run mode, the read-only commands for real, plus shellcheck (no downloads or builds)
- `tests/test_smoke.sh`: Smoke test of the fpga-box env: every tool starts and does one small real job
- `native/`: written by `./fpga-box native` (wrappers in native/bin, native.zsh / native.bash); regenerate, do not edit

## Links

- Yosys feedstock: <https://github.com/conda-forge/yosys-feedstock>; YoWASP: <https://yowasp.org/>
- LiteX: <https://github.com/enjoy-digital/litex>, <https://github.com/litex-hub/litex-boards>; Migen: <https://github.com/m-labs/migen>
- OSS CAD Suite (not used): <https://github.com/YosysHQ/oss-cad-suite-build>; pixi: <https://github.com/prefix-dev/pixi>
- History: `NOTES.md`; design decisions: `docs/design_decisions.md`. Reports: `$BOX/00_09_meta/02_logs/2026_10_25_readability_embedded_tools_verification_report.md`.

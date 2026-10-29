# 32_09_fpga: design decisions

Moved out of `README.md` (nothing removed).

- **Not the OSS CAD Suite.** The [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) nightly (20261024) is 748 MB
  compressed and several GB extracted. It covers Linux/macOS/Windows but is undated-nightly-only, and it has no RISC-V compiler
  for LiteX. The pixi env gives exact versions in a lock file and reuses the Box pattern. If you need its extras (SymbiYosys,
  Amaranth, Gowin/Xilinx open flows, openFPGALoader), its tarball can still be dropped into a sibling ID.
- **nextpnr from YoWASP.** conda-forge has no nextpnr, and the `litex-hub` conda channel packages (nextpnr, icestorm,
  prjtrellis) need boost 1.73 and no longer solve. YoWASP wheels are pure WebAssembly, so the same pin works on every OS.
  Bitstream packers (icepack, ecppack) come with them. The first run compiles the WebAssembly (about 1 min, cached in
  `cache/yowasp`, never `~/.cache`). In the shell the plain names (`nextpnr-ice40`, `icepack` ...) are shims in `cache/shims`.
- **RISC-V compiler.** LiteX looks for `riscv64-linux-gnu-*`. The env maps that name onto conda-forge's
  `riscv64-conda-linux-gnu-*` (shims). LiteX builds its own picolibc and compiler_rt, so a Linux-target GCC compiles the
  bare-metal BIOS fine (rv32im/ilp32). The 1.6 GB xPack `riscv-none-elf-gcc` was not needed.
- **Two compiler activations** (host + cross) fight over `CC`/`CFLAGS`/`BUILD`. `lib/fpga.bash` resets `CC`/`CXX`/`CFLAGS`/`LDFLAGS`
  to the host compiler plus the env's json-c/libevent/zlib. The conda activation exports `BUILD=<triple>`, which clobbered
  boxtool's `$BUILD`; this is fixed in `activate()`.
- **linux-64 only** in `pixi.toml`. Every package also exists for osx-arm64/osx-64: add them to `platforms` and run
  `./fpga-box update --env` on a Mac. Windows: Yosys, Icarus and YoWASP work, but the `litex_sim` core needs a POSIX toolchain (use WSL).
- `litex_sim` needs liteeth, litedram, litescope, pythondata-misc-tapcfg, and json-c + libevent from conda-forge.

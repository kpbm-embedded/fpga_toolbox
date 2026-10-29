# @NAME@ (Icarus Verilog testbench template)

`@NAME@.v` (an up/down counter to replace) and `tb_@NAME@.sv`, a self-checking SystemVerilog testbench: random
stimulus, a reference model, `$fatal` (exit status 1) on errors, VCD in `build/`.

```sh
fpga-box shell -- make test     # PASS/FAIL
fpga-box shell -- make lint     # verilator --lint-only -Wall
fpga-box shell -- make wave     # GTKWave (needs a display)
```

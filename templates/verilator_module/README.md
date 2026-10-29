# @NAME@ (Verilator module template)

`@NAME@.v` (an 8-bit accumulator to replace) and `tb_@NAME@.cpp`, a C++ testbench that checks a
reference model each cycle and writes `@NAME@.vcd`.

```sh
fpga-box shell -- make run      # lint, build the model (-j 8), run: prints PASS/FAIL
fpga-box shell -- make wave     # + GTKWave (needs a display)
```

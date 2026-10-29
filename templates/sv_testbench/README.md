# @NAME@ (SystemVerilog testbench on Verilator)

`@NAME@.sv` (a valid/ready register slice to replace) and `tb_@NAME@.sv`: random back-pressure, a scoreboard
queue and a concurrent assertion, compiled to one binary by `verilator --binary --timing --assert`.

```sh
fpga-box shell -- make test     # PASS/FAIL
fpga-box shell -- make lint
```

# @NAME@ (coverage testbench template)

`@NAME@.sv` (a traffic-light FSM to replace) and `tb_@NAME@.sv` (random stimulus, two `cover property` points),
built with `verilator --binary --coverage`. `make cover` runs it, writes `build/coverage.dat`, an annotated copy of
each source (`build/annotated/`, lines marked `%000000` never ran), an lcov `coverage.info` (for genhtml or CI)
and fails when the DUT's line coverage is below `MIN` (90 %).

```sh
fpga-box shell -- make cover
fpga-box shell -- make cover MIN=100
```

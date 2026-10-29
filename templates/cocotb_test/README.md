# @NAME@ (cocotb test template)

`@NAME@.v` (a saturating adder to replace), `test_@NAME@.py` (cocotb 2.1 tests with a Python reference model)
and `run.py` (cocotb's Python runner: builds and runs, no cocotb Makefiles needed).

```sh
fpga-box shell -- make test             # Icarus Verilog
fpga-box shell -- make test-verilator   # Verilator
fpga-box shell -- make test-all
```

Results: `build/<sim>/results.xml` (JUnit, for CI) and waveforms (`.fst`/`.vcd`) in the same folder.

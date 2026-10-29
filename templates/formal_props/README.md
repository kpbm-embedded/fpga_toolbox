# @NAME@ (formal properties template)

`@NAME@.v` (a round-robin arbiter to replace) with `assume`/`assert`/`cover` under `ifdef FORMAL`. The Makefile
turns the design into an SMT-LIB2 model (`yosys write_smt2`) and runs `yosys-smtbmc` with z3:

```sh
fpga-box shell -- make prove     # bmc (DEPTH cycles from reset) + induction (all cycles) + cover
fpga-box shell -- make bmc DEPTH=40
```

A failing assertion prints `Assert failed in ...` and writes the counterexample to `build/bmc.vcd`.
SymbiYosys (`sby`) is not bundled; this is the same flow it drives, without the `.sby` file.

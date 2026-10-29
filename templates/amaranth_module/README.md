# @NAME@ (Amaranth HDL component template)

`@NAME@.py`: an Amaranth 0.5 `wiring.Component` (a timer with compare match, to replace), a simulation with an
async testbench (VCD in `build/`), Verilog export and an iCE40 synthesis check. Amaranth runs the env's yosys
(`AMARANTH_USE_YOSYS=system`, set by fpga-box).

```sh
fpga-box shell -- make test       # simulate + check
fpga-box shell -- make verilog    # build/@NAME@.v for any other flow
fpga-box shell -- make ice40      # synth_ice40 utilisation
```

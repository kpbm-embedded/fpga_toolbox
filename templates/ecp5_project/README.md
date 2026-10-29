# @NAME@ (ECP5 project template, ULX3S)

Top level for the ULX3S (LFE5U-85F-CABGA381, 25 MHz), its pin file (`ulx3s.lpf`, LEDs, buttons, clock) and a
Makefile for yosys → nextpnr-ecp5 → ecppack.

```sh
fpga-box shell -- make          # build/@NAME@.bit
fpga-box shell -- make test     # + Fmax >= 25 MHz from build/report.json
```

Programming (openFPGALoader, fujprog) is not part of fpga-box: no board is attached here.

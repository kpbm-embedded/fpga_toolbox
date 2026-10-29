# @NAME@ (iCE40 project template)

Top level for the iCEBreaker (iCE40UP5K-SG48, 12 MHz), pin file and a Makefile for the open flow
yosys → nextpnr-ice40 → icepack. `make` writes `build/@NAME@.bin` and `build/report.json` (Fmax).

```sh
fpga-box shell -- make
```

Programming (iceprog/openFPGALoader) is not part of fpga-box: the user owns no FPGA board.

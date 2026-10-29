# @NAME@ (LiteX SoC template, iCEBreaker)

`@NAME@.py` subclasses the litex-boards iCEBreaker `BaseSoC` (VexRiscv minimal at 16 MHz, 128 KB SPRAM, SPI
flash, UART) and adds `PWM`, a Migen module with three CSRs (`pwm_enable`, `pwm_period`, `pwm_width`) on the
green LED. Add your own peripherals the same way (a `Module, AutoCSR` class + one line in `__init__`).

```sh
fpga-box shell -- make test        # export: Verilog, csr.csv/json, BIOS; checks the pwm registers
fpga-box shell -- make bitstream   # + yosys / nextpnr-ice40 / icepack (about 1 min)
```

On the board's BIOS prompt: `mem_write <pwm_width address from csr.csv> 900` then `... pwm_enable 1`.
Flashing (iceprog, openFPGALoader) is not part of fpga-box.

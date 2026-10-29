# @NAME@ (iCE40 project with PLL)

iCEBreaker top (`@NAME@.v`), pins (`icebreaker.pcf`) and a Makefile that first generates the PLL with
`icepll -p` (pad PLL on the 12 MHz clock pin) for `FREQ_OUT` MHz, then runs yosys → nextpnr-ice40 (timing checked
at `FREQ_OUT`) → icepack.

```sh
fpga-box shell -- make test               # 48 MHz
fpga-box shell -- make test FREQ_OUT=36   # after `make` with another frequency, delete build/pll.v first
```

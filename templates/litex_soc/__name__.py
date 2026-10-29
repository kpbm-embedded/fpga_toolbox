#!/usr/bin/env python3
"""@NAME@: LiteX SoC for the iCEBreaker with an own CSR peripheral (template from fpga-box new litex_soc).

The litex-boards iCEBreaker BaseSoC (VexRiscv, SPRAM, SPI flash, UART) plus `pwm`: a PWM on the green LED with
`enable`, `period` and `width` registers the CPU (or the BIOS `mem_write`) can set.
  python @NAME@.py export     gateware Verilog + .ys/.pcf, csr.csv/csr.json, BIOS (RISC-V gcc), in build/
The bitstream step is in the Makefile (YoWASP nextpnr cannot run LiteX's Python pre-pack script).
"""
import argparse
from pathlib import Path

from litex.soc.integration.builder import Builder
from litex.soc.interconnect.csr import AutoCSR, CSRStorage
from litex_boards.targets.icebreaker import BaseSoC
from migen import If, Module, Signal


class PWM(Module, AutoCSR):
    """PWM: the output is high for `width` of every `period` clocks while `enable` is 1."""

    def __init__(self, pad, bits=16):
        self.enable = CSRStorage(1, description="1 = run")
        self.period = CSRStorage(bits, reset=1000, description="period in clocks")
        self.width = CSRStorage(bits, reset=250, description="high time in clocks")
        cnt = Signal(bits)
        self.sync += If(cnt >= self.period.storage - 1, cnt.eq(0)).Else(cnt.eq(cnt + 1))
        self.comb += pad.eq(~(self.enable.storage & (cnt < self.width.storage)))   # LED is active low


class @NAME_UPPER@SoC(BaseSoC):
    def __init__(self, **kwargs):
        super().__init__(bios_flash_offset=0x40000, sys_clk_freq=16e6, with_led_chaser=False,
                         cpu_type="vexriscv", cpu_variant="minimal", **kwargs)
        self.pwm = PWM(self.platform.request("user_ledg_n"))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("action", choices=["export"])
    p.add_argument("--output-dir", default="build")
    a = p.parse_args()
    soc = @NAME_UPPER@SoC()
    out = Path(a.output_dir)
    builder = Builder(soc, output_dir=str(out), csr_csv=str(out / "csr.csv"), csr_json=str(out / "csr.json"),
                      bios_console="lite")
    builder.build(run=False)       # gateware sources + software (BIOS); no yosys/nextpnr run
    print(f"exported {out}/gateware, BIOS {out}/software/bios/bios.bin")


if __name__ == "__main__":
    main()

"""Breathing LED in Amaranth HDL 0.5: PWM whose duty ramps up and down.

python breathe.py sim                 simulate a small instance (width 4) and check the duty ramp
python breathe.py verilog <out.v>     write Verilog for the iCEBreaker build (width 8, ramp ~0.7 s at 12 MHz)
"""
import sys

from amaranth import Module, Signal
from amaranth.back import verilog
from amaranth.lib import wiring
from amaranth.lib.wiring import Out
from amaranth.sim import Simulator


class Breathe(wiring.Component):
    led: Out(1)

    def __init__(self, width=8, step_bits=6):
        self.width, self.step_bits = width, step_bits
        super().__init__()

    def elaborate(self, platform):
        m = Module()
        top = (1 << self.width) - 1
        cnt = Signal(self.width)
        duty = Signal(self.width)
        pre = Signal(self.step_bits)
        up = Signal(init=1)
        m.d.sync += cnt.eq(cnt + 1)
        with m.If(cnt == top):                      # end of a PWM period
            m.d.sync += pre.eq(pre + 1)
            with m.If(pre == (1 << self.step_bits) - 1):
                with m.If(up):
                    m.d.sync += duty.eq(duty + 1)
                    with m.If(duty == top - 1):
                        m.d.sync += up.eq(0)
                with m.Else():
                    m.d.sync += duty.eq(duty - 1)
                    with m.If(duty == 1):
                        m.d.sync += up.eq(1)
        m.d.comb += self.led.eq(cnt < duty)
        return m


def simulate():
    dut = Breathe(width=4, step_bits=1)
    period, steps = 16, 2
    duties = []

    async def bench(ctx):
        for _ in range(2 * 15 * steps):              # one full ramp up and down
            high = 0
            for _ in range(period):
                await ctx.tick()
                high += ctx.get(dut.led)
            duties.append(high)

    sim = Simulator(dut)
    sim.add_clock(1e-6)
    sim.add_testbench(bench)
    sim.run()
    peak = max(duties)
    i = duties.index(peak)
    rising = all(a <= b for a, b in zip(duties[:i], duties[1:i + 1]))
    falling = all(a >= b for a, b in zip(duties[i:], duties[i + 1:]))
    print("duty per period:", duties)
    ok = peak == 15 and duties[0] <= 1 and rising and falling
    print("PASS amaranth sim (ramp 0 -> 15 -> back)" if ok else "FAIL amaranth sim")
    return ok


if __name__ == "__main__":
    if sys.argv[1:2] == ["sim"]:
        sys.exit(0 if simulate() else 1)
    elif sys.argv[1:2] == ["verilog"] and len(sys.argv) == 3:
        with open(sys.argv[2], "w") as f:
            f.write(verilog.convert(Breathe(), name="breathe"))
    else:
        sys.exit(__doc__)

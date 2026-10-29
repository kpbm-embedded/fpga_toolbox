"""@NAME@: Amaranth HDL 0.5 component (template from fpga-box new amaranth_module).

Example: a 32-bit timer with a compare match pulse. Replace with your logic.
  python @NAME@.py sim            simulate and check (exit 1 on failure)
  python @NAME@.py verilog [f]    write Verilog (default build/@NAME@.v)
  python @NAME@.py ice40          + synthesise for the iCEBreaker with yosys/nextpnr-ice40 (no top pins: utilisation only)
"""
import subprocess
import sys
from pathlib import Path

from amaranth import Module, Signal
from amaranth.back import verilog
from amaranth.lib import wiring
from amaranth.lib.wiring import In, Out
from amaranth.sim import Simulator


class Timer(wiring.Component):
    enable: In(1)
    compare: In(32)
    count: Out(32)
    match: Out(1)

    def elaborate(self, platform):
        m = Module()
        with m.If(self.enable):
            with m.If(self.count == self.compare):
                m.d.sync += [self.count.eq(0), self.match.eq(1)]
            with m.Else():
                m.d.sync += [self.count.eq(self.count + 1), self.match.eq(0)]
        with m.Else():
            m.d.sync += self.match.eq(0)
        return m


def sim():
    dut = Timer()
    matches = []

    async def bench(ctx):
        ctx.set(dut.compare, 9)
        ctx.set(dut.enable, 1)
        for cycle in range(100):
            await ctx.tick()
            if ctx.get(dut.match):
                matches.append(cycle)

    s = Simulator(dut)
    s.add_clock(1e-6)
    s.add_testbench(bench)
    with s.write_vcd(str(Path("build") / "@NAME@.vcd")):
        s.run()
    gaps = {b - a for a, b in zip(matches, matches[1:])}
    ok = len(matches) == 10 and gaps == {10}
    print(f"{'PASS' if ok else 'FAIL'} @NAME@: matches at {matches}")
    return ok


def write_verilog(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(verilog.convert(Timer(), name="@NAME@"))
    print(f"wrote {path}")


if __name__ == "__main__":
    Path("build").mkdir(exist_ok=True)
    cmd = sys.argv[1] if len(sys.argv) > 1 else "sim"
    if cmd == "sim":
        sys.exit(0 if sim() else 1)
    elif cmd == "verilog":
        write_verilog(Path(sys.argv[2] if len(sys.argv) > 2 else "build/@NAME@.v"))
    elif cmd == "ice40":
        write_verilog(Path("build/@NAME@.v"))
        subprocess.run(["yosys", "-q", "-p", "synth_ice40 -top @NAME@ -json build/@NAME@.json; tee -o build/stat.txt stat",
                        "build/@NAME@.v"], check=True)
        print(Path("build/stat.txt").read_text().strip().splitlines()[-1])
    else:
        sys.exit(__doc__)

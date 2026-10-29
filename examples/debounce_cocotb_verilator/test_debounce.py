"""cocotb tests for debounce.v on Verilator: bouncy press/release give exactly one rise/fall each."""
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

N = 20  # stable clocks required, must match run.py's parameter


async def start(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut["in"].value = 0
    await ClockCycles(dut.clk, 5)


async def count_pulses(dut, stats):
    while True:
        await RisingEdge(dut.clk)
        stats["rise"] += int(dut.rise.value)
        stats["fall"] += int(dut.fall.value)


async def bounce(dut, final, rng, n_bounces=12):
    """Contact bounce: alternating levels, each held shorter than N clocks, then the final level."""
    for i in range(n_bounces):
        dut["in"].value = final if i % 2 == 0 else 1 - final
        await ClockCycles(dut.clk, rng.randrange(1, N - 2))
    dut["in"].value = final


@cocotb.test()
async def press_release(dut):
    """Three bouncy press/release cycles: level follows, one pulse per edge, latency N + 2 clocks."""
    await start(dut)
    rng = random.Random(7)
    stats = {"rise": 0, "fall": 0}
    cocotb.start_soon(count_pulses(dut, stats))
    for cycle in range(3):
        await bounce(dut, 1, rng)
        for latency in range(1, 3 * N):
            await RisingEdge(dut.clk)
            if dut.level.value == 1:
                break
        assert dut.level.value == 1, f"cycle {cycle}: level never rose"
        assert N <= latency <= N + 3, f"press latency {latency}"
        await ClockCycles(dut.clk, 2 * N)
        await bounce(dut, 0, rng)
        await ClockCycles(dut.clk, 2 * N)
        assert dut.level.value == 0, f"cycle {cycle}: level stuck high"
    assert stats == {"rise": 3, "fall": 3}, stats
    dut._log.info("PASS press_release: %s, last press latency %d clocks", stats, latency)


@cocotb.test()
async def glitch_ignored(dut):
    """Single short spikes never change the level."""
    await start(dut)
    for width in (1, N // 2, N - 3):
        dut["in"].value = 1
        await ClockCycles(dut.clk, width)
        dut["in"].value = 0
        await ClockCycles(dut.clk, 2 * N)
        assert dut.level.value == 0, f"spike of {width} clocks got through"
    dut._log.info("PASS glitch_ignored")

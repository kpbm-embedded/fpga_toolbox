"""cocotb tests for @NAME@ (run by run.py). Edit the reference model and the tests with your design."""
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge


def model(a, b):
    s = a + b
    return (0xFFFF, 1) if s > 0xFFFF else (s, 0)


@cocotb.test()
async def random_vectors(dut):
    """1000 random inputs against the Python model."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    rng = random.Random(0)
    for _ in range(1000):
        a, b = rng.randrange(1 << 16), rng.randrange(1 << 16)
        await FallingEdge(dut.clk)
        dut.a.value, dut.b.value = a, b
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        got = (dut.sum.value.to_unsigned(), int(dut.sat.value))
        assert got == model(a, b), f"{a} + {b}: got {got}, want {model(a, b)}"


@cocotb.test()
async def corner_cases(dut):
    """Zero, the largest non-saturating sum, and saturation."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    for a, b in [(0, 0), (0xFFFF, 0), (0x8000, 0x7FFF), (0x8000, 0x8000), (0xFFFF, 0xFFFF)]:
        await FallingEdge(dut.clk)
        dut.a.value, dut.b.value = a, b
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        assert (dut.sum.value.to_unsigned(), int(dut.sat.value)) == model(a, b)

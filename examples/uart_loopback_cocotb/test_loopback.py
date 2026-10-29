"""cocotb tests for the UART loopback (uart_tx -> uart_rx), run by run.py on Icarus Verilog."""
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

CPB = 8  # clocks per bit, must match the HDL parameter


async def reset(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.tx_valid.value = 0
    dut.inject.value = 0
    dut.ext_rx.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)


async def collect(dut, n, out):
    """Monitor: append every received byte (rx_valid pulse) to out."""
    while len(out) < n:
        await RisingEdge(dut.clk)
        if dut.rx_valid.value == 1:
            out.append(dut.rx_data.value.to_unsigned())


@cocotb.test()
async def random_bytes(dut):
    """64 random bytes through the transmitter arrive unchanged and in order."""
    await reset(dut)
    rng = random.Random(1)
    data = [rng.randrange(256) for _ in range(64)]
    got = []
    mon = cocotb.start_soon(collect(dut, len(data), got))
    for b in data:
        while dut.tx_ready.value != 1:
            await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        dut.tx_data.value = b
        dut.tx_valid.value = 1
        await FallingEdge(dut.clk)
        dut.tx_valid.value = 0
    await mon
    assert got == data, f"mismatch: {got[:8]} vs {data[:8]}"
    dut._log.info("PASS random_bytes: %d bytes", len(got))


async def drive_line(dut, byte, stop=1):
    """Bit-level driver: put one 8N1 frame on ext_rx (LSB first)."""
    for bit in [0] + [(byte >> i) & 1 for i in range(8)] + [stop, 1]:
        dut.ext_rx.value = bit
        await ClockCycles(dut.clk, CPB)


@cocotb.test()
async def framing_error(dut):
    """A frame with stop bit 0 raises rx_frame_err and delivers no byte; the next frame is fine."""
    await reset(dut)
    dut.inject.value = 1
    seen = {"err": 0, "bytes": []}

    async def watch():
        while True:
            await RisingEdge(dut.clk)
            if dut.rx_frame_err.value == 1:
                seen["err"] += 1
            if dut.rx_valid.value == 1:
                seen["bytes"].append(dut.rx_data.value.to_unsigned())

    cocotb.start_soon(watch())
    await drive_line(dut, 0x3C, stop=0)
    await drive_line(dut, 0xC3)
    await ClockCycles(dut.clk, 4 * CPB)
    assert seen["err"] == 1 and seen["bytes"] == [0xC3], seen
    dut._log.info("PASS framing_error")

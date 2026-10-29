"""Build the loopback with Icarus and run test_loopback.py through cocotb's Python runner.
Usage: python run.py <build-dir>    (exit 1 when a test fails)"""
import sys
from pathlib import Path

from cocotb_tools.runner import get_results, get_runner

here = Path(__file__).resolve().parent
build = Path(sys.argv[1]).resolve()
rtl = here.parent / "common" / "rtl"
runner = get_runner("icarus")
runner.build(sources=[rtl / "uart_tx.v", rtl / "uart_rx.v", here / "loopback.v"], hdl_toplevel="loopback",
             build_dir=build, timescale=("1ns", "1ps"), waves=True, always=True)
xml = runner.test(hdl_toplevel="loopback", test_module="test_loopback", test_dir=here, build_dir=build,
                  results_xml=build / "results.xml", waves=True)
total, failed = get_results(xml)
print(f"cocotb: {total} tests, {failed} failed")
print("PASS uart_loopback_cocotb" if total and not failed else "FAIL")
sys.exit(1 if failed or not total else 0)

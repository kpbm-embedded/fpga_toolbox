"""Build debounce.v with Verilator (N = 20) and run test_debounce.py through cocotb's runner.
Usage: python run.py <build-dir> [jobs]"""
import sys
from pathlib import Path

from cocotb_tools.runner import get_results, get_runner

here = Path(__file__).resolve().parent
build = Path(sys.argv[1]).resolve()
jobs = sys.argv[2] if len(sys.argv) > 2 else "4"
runner = get_runner("verilator")
runner.build(sources=[here.parent / "common" / "rtl" / "debounce.v"], hdl_toplevel="debounce",
             parameters={"N": 20}, build_dir=build, build_args=["-j", jobs, "-Wno-fatal"], waves=True,
             timescale=("1ns", "1ps"))
xml = runner.test(hdl_toplevel="debounce", test_module="test_debounce", test_dir=here, build_dir=build,
                  results_xml=build / "results.xml", waves=True)
total, failed = get_results(xml)
print(f"cocotb: {total} tests, {failed} failed")
print("PASS debounce_cocotb_verilator" if total and not failed else "FAIL")
sys.exit(1 if failed or not total else 0)

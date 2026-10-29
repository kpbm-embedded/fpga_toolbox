"""Build @NAME@.v and run test_@NAME@.py with cocotb's Python runner.
Usage: python run.py [icarus|verilator]   (default icarus; results and waves in build/<sim>/)"""
import sys
from pathlib import Path

from cocotb_tools.runner import get_results, get_runner

here = Path(__file__).resolve().parent
sim = sys.argv[1] if len(sys.argv) > 1 else "icarus"
build = here / "build" / sim
runner = get_runner(sim)
extra = {"build_args": ["-j", "8", "-Wno-fatal"]} if sim == "verilator" else {}
runner.build(sources=[here / "@NAME@.v"], hdl_toplevel="@NAME@", build_dir=build, waves=True,
             timescale=("1ns", "1ps"), **extra)
xml = runner.test(hdl_toplevel="@NAME@", test_module="test_@NAME@", test_dir=here, build_dir=build,
                  results_xml=build / "results.xml", waves=True)
total, failed = get_results(xml)
print(f"{'PASS' if total and not failed else 'FAIL'} @NAME@ ({sim}): {total} tests, {failed} failed")
sys.exit(1 if failed or not total else 0)

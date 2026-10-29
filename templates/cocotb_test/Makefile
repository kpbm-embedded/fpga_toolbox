# @NAME@: cocotb tests. Use inside `fpga-box shell`.  make [test|test-verilator|test-all]
export PYTHONDONTWRITEBYTECODE=1
test:
	python run.py icarus
test-verilator:
	python run.py verilator
test-all: test test-verilator
.PHONY: test test-verilator test-all

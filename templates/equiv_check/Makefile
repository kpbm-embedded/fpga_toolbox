# @NAME@: formal equivalence of gold.v and gate.v. Use inside `fpga-box shell`.  make [test|equiv|miter]
test: equiv miter
	@echo "PASS @NAME@: gate.v == gold.v"
equiv:
	yosys -q -s equiv.ys
miter:
	yosys -q -s miter.ys
.PHONY: test equiv miter

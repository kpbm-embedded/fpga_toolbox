// Verilator C++ testbench for @NAME@: drives inputs, checks a reference model, writes a VCD.
#include <cstdio>
#include <memory>
#include "V@NAME@.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    auto ctx = std::make_unique<VerilatedContext>();
    ctx->commandArgs(argc, argv);
    ctx->traceEverOn(true);
    auto dut = std::make_unique<V@NAME@>(ctx.get());
    VerilatedVcdC vcd; dut->trace(&vcd, 99); vcd.open("@NAME@.vcd");
    unsigned model = 0, errors = 0; uint64_t t = 0;
    auto tick = [&] { dut->clk = 0; dut->eval(); vcd.dump(t++); dut->clk = 1; dut->eval(); vcd.dump(t++); };
    dut->rst = 1; tick(); dut->rst = 0;
    for (unsigned i = 1; i <= 100; i++) {
        dut->a = i & 0xff; tick();
        model = (model + (i & 0xff)) & 0xff;
        if (dut->q != model) { printf("FAIL cycle %u: q=%u want %u\n", i, dut->q, model); errors++; }
    }
    vcd.close();
    printf(errors ? "FAIL @NAME@ (%u errors)\n" : "PASS @NAME@\n", errors);
    return errors ? 1 : 0;
}

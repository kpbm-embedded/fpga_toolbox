// Verilator C++ testbench: sends a string through uart_tx, decodes the serial line by
// sampling mid-bit, checks every byte, writes a VCD. Exit 0 = PASS.
#include <cstdio>
#include <cstring>
#include <memory>
#include "Vuart_tx.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static const int CPB = 16;   // must match CLKS_PER_BIT
int main(int argc, char** argv) {
    auto ctx = std::make_unique<VerilatedContext>();
    ctx->commandArgs(argc, argv);
    ctx->traceEverOn(true);
    auto top = std::make_unique<Vuart_tx>(ctx.get());
    auto vcd = std::make_unique<VerilatedVcdC>();
    top->trace(vcd.get(), 99);
    const char* vcdpath = getenv("VCD") ? getenv("VCD") : "uart_tx.vcd";
    vcd->open(vcdpath);
    const char* msg = "Hello, fpga-box!";
    size_t sent = 0, got = 0; char rx[64] = {0};
    int state = 0, cnt = 0, bit = 0; unsigned byte = 0;   // decoder
    uint64_t t = 0;
    top->rst = 1; top->clk = 0;
    for (; t < 400000 && got < strlen(msg); t++) {
        top->clk = !top->clk;
        if (t == 10) top->rst = 0;
        if (top->clk) {   // rising edge: drive inputs for the next cycle
            top->valid = 0;
            if (!top->rst && top->ready && sent < strlen(msg) && (t % 4 == 0)) { top->data = msg[sent++]; top->valid = 1; }
        }
        top->eval();
        vcd->dump(t);
        if (!top->clk) continue;
        // line decoder (8N1)
        switch (state) {
            case 0: if (!top->tx && !top->rst) { state = 1; cnt = CPB / 2; } break;
            case 1: if (--cnt == 0) { if (top->tx) { state = 0; break; } state = 2; cnt = CPB; bit = 0; byte = 0; } break;
            case 2: if (--cnt == 0) { byte |= (top->tx ? 1u : 0u) << bit; cnt = CPB;
                      if (++bit == 8) state = 3; } break;
            case 3: if (--cnt == 0) { if (!top->tx) { printf("FAIL framing error at byte %zu\n", got); return 1; }
                      rx[got++] = (char)byte; state = 0; } break;
        }
    }
    vcd->close();
    printf("received: \"%s\" (%zu bytes, %llu half-cycles, VCD %s)\n", rx, got, (unsigned long long)t, vcdpath);
    if (strcmp(rx, msg) != 0) { printf("FAIL expected \"%s\"\n", msg); return 1; }
    printf("PASS uart_tx\n");
    return 0;
}

// Verilator C++ testbench for spi_master: a behavioural SPI slave (all 4 modes) answers every transfer;
// checks full-duplex data both ways, SCLK idle level (CPOL), 16 SCLK edges per byte and cs_n framing.
#include <cstdio>
#include <cstdlib>
#include <memory>
#include "Vspi_master.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

struct Slave {  // SPI mode 0-3 slave, MSB first
    int cpol = 0, cpha = 0, bit = 0;
    uint8_t tx = 0, rx = 0;
    int last_sclk = 0, last_cs = 1, edges = 0;
    void step(Vspi_master& m, uint8_t reply) {
        if (last_cs && !m.cs_n) {            // select: load the reply; CPHA=0 drives its MSB now
            tx = reply; rx = 0; bit = 0; edges = 0;
            if (!cpha) m.miso = (tx >> 7) & 1;
        }
        if (!m.cs_n && m.sclk != last_sclk) {
            bool leading = (m.sclk != cpol);
            edges++;
            if (leading == !cpha) rx = (uint8_t)((rx << 1) | m.mosi);          // sample edge
            else {                                                              // shift edge
                if (cpha) m.miso = (tx >> (7 - bit)) & 1;
                else if (bit < 7) m.miso = (tx >> (6 - bit)) & 1;
                bit++;
            }
        }
        last_sclk = m.sclk; last_cs = m.cs_n;
    }
};

int main(int argc, char** argv) {
    auto ctx = std::make_unique<VerilatedContext>();
    ctx->commandArgs(argc, argv);
    ctx->traceEverOn(true);
    Vspi_master m{ctx.get()};
    VerilatedVcdC vcd;
    const char* vcd_path = getenv("VCD");
    if (vcd_path) { m.trace(&vcd, 99); vcd.open(vcd_path); }
    uint64_t t = 0;
    Slave s;
    uint8_t reply = 0;
    auto tick = [&]() {
        m.clk = 0; m.eval(); if (vcd_path) vcd.dump(t++);
        m.clk = 1; m.eval(); s.step(m, reply); m.eval(); if (vcd_path) vcd.dump(t++);
    };
    int errors = 0, transfers = 0;
    m.rst = 1; m.start = 0; m.miso = 0;
    for (int i = 0; i < 4; i++) tick();
    m.rst = 0;
    const uint8_t data[] = {0xA5, 0x3C, 0x00, 0xFF, 0x81, 0x7E};
    for (int mode = 0; mode < 4; mode++) {
        m.cpol = s.cpol = mode >> 1; m.cpha = s.cpha = mode & 1;
        tick(); tick();
        if (m.sclk != m.cpol) { printf("FAIL mode %d: SCLK idles at %d\n", mode, m.sclk); errors++; }
        for (uint8_t d : data) {
            reply = (uint8_t)~d ^ (uint8_t)mode;
            m.tx = d; m.start = 1; tick(); m.start = 0;
            int guard = 0;
            while (!m.done && guard++ < 1000) tick();
            transfers++;
            if (m.rx != reply || s.rx != d || s.edges != 16) {
                printf("FAIL mode %d: sent %02x slave got %02x, reply %02x master got %02x, edges %d\n",
                       mode, d, s.rx, reply, m.rx, s.edges);
                errors++;
            }
            tick();
            if (!m.cs_n || m.busy) { printf("FAIL mode %d: cs_n/busy after done\n", mode); errors++; }
        }
        printf("mode %d (CPOL=%d CPHA=%d): %zu transfers ok\n", mode, mode >> 1, mode & 1, sizeof data);
    }
    if (vcd_path) vcd.close();
    m.final();
    printf("%s spi_master: %d transfers, %d errors\n", errors ? "FAIL" : "PASS", transfers, errors);
    return errors ? 1 : 0;
}

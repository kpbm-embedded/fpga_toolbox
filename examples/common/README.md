# examples/common: shared RTL (not an example itself)

- `rtl/uart_tx.v`, `rtl/uart_rx.v`: 8N1 UART transmitter / receiver (2-FF synchroniser, mid-bit sampling, framing error).
- `rtl/sync_fifo.v`: synchronous FIFO (power-of-two depth, full/empty/count) with formal properties under `ifdef FORMAL`.
- `rtl/debounce.v`: 2-FF synchroniser + stable-for-N-clocks debouncer with press/release pulses.
- `rtl/pwm.v`: N-bit PWM with a duty register that is loaded only at the end of a period (glitch-free).
- `rtl/spi_master.v`: SPI master, modes 0-3 (CPOL/CPHA), 8-bit transfers, clock divider.

All are Verilog-2005 (`default_nettype none`) plus SystemVerilog size casts (`W'(x)`), so yosys reads them with
`read_verilog -sv`; all are lint clean under `verilator --lint-only -Wall`.

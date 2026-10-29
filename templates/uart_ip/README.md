# @NAME@ (UART IP template)

`@NAME@_tx.v` / `@NAME@_rx.v`: 8N1 UART transmitter and receiver (`CLKS_PER_BIT = clock / baud`; the receiver
has a 2-FF synchroniser, mid-bit sampling and a framing-error pulse). `tb_@NAME@.sv` sends 32 random bytes through
a TX -> RX loopback at 115200 baud from 12 MHz.

```sh
fpga-box shell -- make test             # Icarus
fpga-box shell -- make test-verilator   # Verilator --binary
fpga-box shell -- make lint synth
```

For a real board connect `tx` to the USB-UART's RX pin (iCEBreaker: pin 9) and watch it with `serial-box`.

// loopback: uart_tx -> wire -> uart_rx, the line is also a port so cocotb can watch or drive it.
`default_nettype none
module loopback #(parameter integer CLKS_PER_BIT = 8) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_ready,
    input  wire       inject,       // 1: rx listens to ext_rx instead of the transmitter
    input  wire       ext_rx,
    output wire       line,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       rx_frame_err
);
    wire tx;
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (.clk, .rst, .data(tx_data), .valid(tx_valid), .ready(tx_ready), .tx);
    assign line = inject ? ext_rx : tx;
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (.clk, .rst, .rx(line), .data(rx_data), .valid(rx_valid), .frame_err(rx_frame_err));
endmodule

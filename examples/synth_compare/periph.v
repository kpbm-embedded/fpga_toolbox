// periph: a small peripheral block (UART TX + RX, SPI master, 16-entry FIFO, PWM) used to compare how big
// the same RTL is on different FPGA families. Inputs and outputs are kept so nothing is optimised away.
`default_nettype none
module periph (
    input  wire       clk, rst,
    input  wire [7:0] wdata,
    input  wire       wr, rd, start, cpol, cpha, uart_rx,
    input  wire       miso,
    output wire [7:0] rdata, spi_rx, rx_data,
    output wire       full, empty, busy, done, sclk, mosi, cs_n,
    output wire       uart_tx, tx_ready, rx_valid, rx_err, pwm_out, pwm_end
);
    wire [4:0] count;
    sync_fifo #(.DW(8), .AW(4)) u_fifo (.clk, .rst, .wr_en(wr), .wr_data(wdata), .rd_en(rd), .rd_data(rdata), .full, .empty, .count);
    spi_master #(.DIV(4)) u_spi (.clk, .rst, .cpol, .cpha, .start, .tx(rdata), .rx(spi_rx), .busy, .done, .sclk, .mosi, .miso, .cs_n);
    uart_tx #(.CLKS_PER_BIT(104)) u_tx (.clk, .rst, .data(rdata), .valid(rd), .ready(tx_ready), .tx(uart_tx));
    uart_rx #(.CLKS_PER_BIT(104)) u_rx (.clk, .rst, .rx(uart_rx), .data(rx_data), .valid(rx_valid), .frame_err(rx_err));
    pwm #(.N(8)) u_pwm (.clk, .rst, .duty(rdata ^ {3'b000, count}), .out(pwm_out), .period_end(pwm_end));
endmodule

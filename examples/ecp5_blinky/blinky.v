// blinky for ULX3S (LFE5U-85F, 25 MHz): 8 LEDs show the top bits of a counter.
`default_nettype none
module top (input wire clk_25mhz, output wire [7:0] led);
    reg [27:0] cnt = 0;
    always @(posedge clk_25mhz) cnt <= cnt + 1'b1;
    assign led = cnt[27:20];
endmodule

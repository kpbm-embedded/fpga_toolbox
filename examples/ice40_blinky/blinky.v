// blinky for iCEBreaker (iCE40UP5K-SG48, 12 MHz): red/green LEDs (active low) from a counter.
`default_nettype none
module top (input wire CLK, output wire LEDR_N, output wire LEDG_N);
    reg [24:0] cnt = 0;
    always @(posedge CLK) cnt <= cnt + 1'b1;
    assign LEDR_N = ~cnt[24];
    assign LEDG_N = ~cnt[23];
endmodule

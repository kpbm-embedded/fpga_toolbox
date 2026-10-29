// iCEBreaker top: the Amaranth-generated `breathe` drives the green LED (active low), red stays off.
`default_nettype none
module top (input wire CLK, output wire LEDG_N, output wire LEDR_N);
    wire led;
    breathe u (.clk(CLK), .rst(1'b0), .led(led));
    assign LEDG_N = ~led;
    assign LEDR_N = 1'b1;
endmodule

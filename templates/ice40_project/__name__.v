// @NAME@: iCEBreaker (iCE40UP5K-SG48, 12 MHz) top level (template from fpga-box new ice40_project)
`default_nettype none
module top (input wire CLK, input wire BTN_N, output wire LEDR_N, output wire LEDG_N);
    reg [23:0] cnt = 0;
    always @(posedge CLK) cnt <= cnt + 1'b1;
    assign LEDR_N = ~cnt[23];
    assign LEDG_N = BTN_N;     // green LED on while the user button is pressed (both active low)
endmodule

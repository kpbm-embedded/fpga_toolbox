// @NAME@: replace with your logic (template from fpga-box new icarus_tb). Example: 8-bit up/down counter.
`default_nettype none
module @NAME@ (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       up,
    output reg  [7:0] q
);
    always @(posedge clk)
        if (rst) q <= 8'd0;
        else if (en) q <= up ? q + 8'd1 : q - 8'd1;
endmodule

// @NAME@: replace with your logic (template from fpga-box new cocotb_test). Example: 16-bit saturating adder
// with a registered output.
`default_nettype none
module @NAME@ (
    input  wire        clk,
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [15:0] sum,
    output reg         sat
);
    wire [16:0] s = {1'b0, a} + {1'b0, b};
    always @(posedge clk) begin
        sat <= s[16];
        sum <= s[16] ? 16'hffff : s[15:0];
    end
endmodule

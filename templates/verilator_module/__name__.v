// @NAME@: replace with your logic (template from fpga-box new verilator_module)
`default_nettype none
module @NAME@ #(parameter integer N = 8) (
    input  wire         clk,
    input  wire         rst,
    input  wire [N-1:0] a,
    output reg  [N-1:0] q
);
    always @(posedge clk)
        if (rst) q <= {N{1'b0}};
        else     q <= q + a;   // accumulator
endmodule

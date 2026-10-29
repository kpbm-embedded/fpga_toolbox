// counter: N-bit up counter with enable and synchronous clear; wrap flag on overflow.
`default_nettype none
module counter #(parameter integer N = 8) (
    input  wire         clk, rst, en, clr,
    output reg [N-1:0]  q,
    output wire         wrap
);
    assign wrap = en && (q == {N{1'b1}});
    always @(posedge clk)
        if (rst || clr) q <= {N{1'b0}};
        else if (en) q <= q + 1'b1;
endmodule

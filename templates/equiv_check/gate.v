// @NAME@ optimised (gate): shift-and-add multiplier written out by hand; must equal gold.v.
`default_nettype none
module @NAME@ (input wire [7:0] a, input wire [7:0] b, output reg [15:0] p);
    integer i;
    always @(*) begin
        p = 16'd0;
        for (i = 0; i < 8; i = i + 1)
            if (b[i]) p = p + ({8'd0, a} << i);
    end
endmodule

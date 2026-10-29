// Reference (gold) implementations: obvious code.
`default_nettype none
module popcount8 (input wire [7:0] x, output wire [3:0] n);
    assign n = x[0] + x[1] + x[2] + x[3] + x[4] + x[5] + x[6] + x[7];
endmodule
// Gray-code counter as "binary counter + bin2gray"
module gray4 (input wire clk, input wire rst, input wire en, output wire [3:0] g);
    reg [3:0] b;
    always @(posedge clk) if (rst) b <= 4'd0; else if (en) b <= b + 4'd1;
    assign g = b ^ (b >> 1);
endmodule

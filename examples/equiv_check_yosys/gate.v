// Optimised (gate) implementations to prove equal to gold.v.
`default_nettype none
module popcount8 (input wire [7:0] x, output wire [3:0] n);
    // SWAR-style adder tree: pairs, nibbles, byte
    wire [7:0] p = (x & 8'h55) + ((x >> 1) & 8'h55);
    wire [7:0] q = (p & 8'h33) + ((p >> 2) & 8'h33);
    wire [7:0] r = (q & 8'h0f) + ((q >> 4) & 8'h0f);
`ifdef BUG
    assign n = r[3:0] ^ {3'b000, x[7] & x[0]};      // seeded bug
`else
    assign n = r[3:0];
`endif
endmodule
// Gray counter that keeps only the Gray state and flips one bit per step (no binary register)
module gray4 (input wire clk, input wire rst, input wire en, output reg [3:0] g);
    wire parity = ^g;
    wire [3:0] low1 = g & -g;                               // lowest set bit
    always @(posedge clk)
        if (rst) g <= 4'd0;
        else if (en) begin
            if (!parity) g <= g ^ 4'b0001;                  // even parity: flip bit 0
            else if (low1 == 4'b1000) g <= g ^ 4'b1000;     // wrap 1000 -> 0000
            else g <= g ^ (low1 << 1);                      // else flip the bit left of the lowest 1
        end
endmodule

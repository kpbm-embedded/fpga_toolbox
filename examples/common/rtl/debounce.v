// debounce: button input -> clean level. 2-FF synchroniser, then the level changes only after the
// input was stable for N clocks (N = clock * settle time, e.g. 12 MHz * 10 ms = 120000).
// rise/fall pulse one clock on press/release.
`default_nettype none
/* verilator lint_off PROCASSINIT */  // FPGA power-on values (iCE40/ECP5 registers start at their init value)
module debounce #(parameter integer N = 1000) (
    input  wire clk,
    input  wire in,
    output reg  level = 1'b0,
    output reg  rise = 1'b0,
    output reg  fall = 1'b0
);
    localparam integer W = $clog2(N + 1);
    reg s0 = 1'b0, s1 = 1'b0;
    reg [W-1:0] cnt = {W{1'b0}};
    always @(posedge clk) begin
        s0 <= in; s1 <= s0;
        rise <= 1'b0; fall <= 1'b0;
        if (s1 == level) cnt <= {W{1'b0}};
        else if (cnt == W'(N - 1)) begin
            cnt <= {W{1'b0}}; level <= s1; rise <= s1; fall <= !s1;
        end else cnt <= cnt + 1'b1;
    end
endmodule

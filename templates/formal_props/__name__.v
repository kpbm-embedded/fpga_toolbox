// @NAME@: replace with your logic (template from fpga-box new formal_props). Example: round-robin arbiter
// for 4 requesters. Properties live under `ifdef FORMAL` and are proven by make prove (yosys-smtbmc + z3).
`default_nettype none
module @NAME@ (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] req,
    output reg  [3:0] grant
);
    reg [1:0] last;
    integer i;
    reg [1:0] idx;
    reg found;
    always @(*) begin                      // first requester after the last one granted
        found = 1'b0; idx = last;
        for (i = 1; i <= 4; i = i + 1)
            if (!found && req[(last + i) % 4]) begin found = 1'b1; idx = 2'((last + i) % 4); end
    end
    always @(posedge clk)
        if (rst) begin grant <= 4'd0; last <= 2'd3; end
        else begin
            grant <= found ? (4'd1 << idx) : 4'd0;
            if (found) last <= idx;
        end
`ifdef FORMAL
    reg past_ok = 1'b0;
    always @(posedge clk) past_ok <= 1'b1;
    always @(*) if (!past_ok) assume (rst);
    always @(posedge clk) if (past_ok && !$past(rst)) begin
        assert ((grant & (grant - 4'd1)) == 4'd0);          // at most one grant (one-hot or zero)
        assert ((grant & ~$past(req)) == 4'd0);              // only to a requester
        if ($past(req) != 4'd0) assert (grant != 4'd0);      // work conserving
    end
    always @(posedge clk) if (past_ok && !rst) cover (grant == 4'b1000);
`endif
endmodule

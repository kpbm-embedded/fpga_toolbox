// sync_fifo: synchronous FIFO, DEPTH = 2**AW entries of DW bits. Writes when full and reads when empty
// are ignored. With -DFORMAL (yosys read_verilog -formal) the block at the end adds assertions that a
// solver proves for every input sequence (see examples/fifo_formal).
`default_nettype none
module sync_fifo #(parameter integer DW = 8, parameter integer AW = 2) (
    input  wire          clk,
    input  wire          rst,
    input  wire          wr_en,
    input  wire [DW-1:0] wr_data,
    input  wire          rd_en,
    output wire [DW-1:0] rd_data,
    output wire          full,
    output wire          empty,
    output reg  [AW:0]   count
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    reg [AW:0] wp, rp;                         // one extra bit tells full from empty
    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;
    assign empty = (wp == rp);
    assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);
    assign rd_data = mem[rp[AW-1:0]];
    always @(posedge clk) begin
        if (rst) begin wp <= 0; rp <= 0; count <= 0; end
        else begin
            if (do_wr) begin mem[wp[AW-1:0]] <= wr_data; wp <= wp + 1'b1; end
            if (do_rd) rp <= rp + 1'b1;
            count <= count + {{AW{1'b0}}, do_wr} - {{AW{1'b0}}, do_rd};
        end
    end
`ifdef FORMAL
    reg past_ok = 1'b0;
    always @(posedge clk) past_ok <= 1'b1;
    always @(*) if (!past_ok) assume (rst);
    always @(posedge clk) if (past_ok && !$past(rst)) begin
        assert (count == wp - rp);                       // count tracks the pointers
        assert (count <= (1 << AW));                     // never more than DEPTH
        assert (full  == (count == (1 << AW)));
        assert (empty == (count == 0));
        if ($past(full) && $past(wr_en) && !$past(rd_en)) assert (wp == $past(wp));   // no overwrite when full
        if ($past(empty) && $past(rd_en)) assert (rp == $past(rp));                      // no underflow
    end
    always @(posedge clk) if (past_ok) cover (full);     // the FIFO can actually fill
`endif
endmodule

// @NAME@_rx: 8N1 UART receiver. CLKS_PER_BIT = clock / baud. 2-FF synchroniser on rx, the start bit is
// re-checked at its middle (glitch filter), data bits are sampled mid-bit. frame_err pulses when the
// stop bit is 0 (the byte is dropped).
`default_nettype none
/* verilator lint_off PROCASSINIT */  // FPGA power-on values (iCE40/ECP5 registers start at their init value)
module @NAME@_rx #(parameter integer CLKS_PER_BIT = 16) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,      // one-clock pulse with data
    output reg        frame_err   // one-clock pulse: stop bit was 0
);
    localparam integer W = $clog2(CLKS_PER_BIT);
    localparam [1:0] IDLE = 2'd0, START = 2'd1, BITS = 2'd2, STOP = 2'd3;
    reg       rx_m = 1'b1, rx_s = 1'b1;
    reg [1:0] st;
    reg [W-1:0] cnt;
    reg [2:0] bitn;
    reg [7:0] shreg;
    always @(posedge clk) begin rx_m <= rx; rx_s <= rx_m; end
    always @(posedge clk) begin
        valid <= 1'b0; frame_err <= 1'b0;
        if (rst) begin
            st <= IDLE; cnt <= {W{1'b0}}; bitn <= 3'd0; shreg <= 8'd0; data <= 8'd0;
        end else case (st)
            IDLE:  if (!rx_s) begin st <= START; cnt <= {W{1'b0}}; end
            START: if (cnt == W'(CLKS_PER_BIT / 2 - 1)) begin
                       cnt <= {W{1'b0}}; bitn <= 3'd0;
                       st <= rx_s ? IDLE : BITS;          // glitch: back to idle
                   end else cnt <= cnt + 1'b1;
            BITS:  if (cnt == W'(CLKS_PER_BIT - 1)) begin
                       cnt <= {W{1'b0}}; shreg <= {rx_s, shreg[7:1]}; bitn <= bitn + 3'd1;
                       if (bitn == 3'd7) st <= STOP;
                   end else cnt <= cnt + 1'b1;
            STOP:  if (cnt == W'(CLKS_PER_BIT - 1)) begin
                       st <= IDLE;
                       if (rx_s) begin data <= shreg; valid <= 1'b1; end else frame_err <= 1'b1;
                   end else cnt <= cnt + 1'b1;
        endcase
    end
endmodule

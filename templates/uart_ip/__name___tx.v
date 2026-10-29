// @NAME@_tx: 8N1 UART transmitter. CLKS_PER_BIT = clock / baud.
`default_nettype none
module @NAME@_tx #(parameter integer CLKS_PER_BIT = 16) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       valid,    // pulse with data when ready=1
    output wire       ready,
    output reg        tx
);
    localparam integer W = $clog2(CLKS_PER_BIT);
    reg [W-1:0] cnt;
    reg [3:0]   bitn;     // 0 = idle, 1 = start, 2..9 = data, 10 = stop
    reg [7:0]   shreg;
    assign ready = (bitn == 4'd0);
    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; bitn <= 4'd0; cnt <= {W{1'b0}}; shreg <= 8'd0;
        end else if (bitn == 4'd0) begin
            tx <= 1'b1;
            if (valid) begin shreg <= data; bitn <= 4'd1; cnt <= {W{1'b0}}; tx <= 1'b0; end
        end else if (cnt == W'(CLKS_PER_BIT - 1)) begin
            cnt <= {W{1'b0}};
            if (bitn == 4'd10) bitn <= 4'd0;
            else begin
                bitn <= bitn + 4'd1;
                if (bitn <= 4'd8) begin tx <= shreg[0]; shreg <= {1'b0, shreg[7:1]}; end
                else tx <= 1'b1;   // stop bit
            end
        end else cnt <= cnt + 1'b1;
    end
endmodule

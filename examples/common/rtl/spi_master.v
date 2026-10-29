// spi_master: 8-bit SPI master, all four modes (CPOL, CPHA), MSB first. SCLK = clk / (2 * DIV).
// Pulse `start` with `tx` while `busy` is 0; `done` pulses with the received byte in `rx`.
// cs_n is driven low for the transfer (one device; add a decoder for more).
`default_nettype none
module spi_master #(parameter integer DIV = 4) (
    input  wire       clk,
    input  wire       rst,
    input  wire       cpol,
    input  wire       cpha,
    input  wire       start,
    input  wire [7:0] tx,
    output reg  [7:0] rx,
    output reg        busy,
    output reg        done,
    output reg        sclk,
    output reg        mosi,
    input  wire       miso,
    output reg        cs_n
);
    localparam integer W = $clog2(DIV);
    reg [W-1:0] div;
    reg [4:0]   edges;          // 16 SCLK edges per byte
    reg [7:0]   sh_tx, sh_rx;
    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0; cs_n <= 1'b1; sclk <= 1'b0; mosi <= 1'b0; div <= {W{1'b0}};
            edges <= 5'd0; sh_tx <= 8'd0; sh_rx <= 8'd0; rx <= 8'd0;
        end else if (!busy) begin
            sclk <= cpol;
            if (start) begin
                busy <= 1'b1; cs_n <= 1'b0; div <= {W{1'b0}}; edges <= 5'd0;
                sh_tx <= tx; mosi <= cpha ? 1'b0 : tx[7];   // CPHA=0: first bit valid before the first edge
            end
        end else if (div == W'(DIV - 1)) begin
            div <= {W{1'b0}};
            if (edges == 5'd16) begin            // end of the byte
                busy <= 1'b0; cs_n <= 1'b1; done <= 1'b1; rx <= sh_rx;
            end else begin
                sclk <= ~sclk; edges <= edges + 5'd1;
                // leading edges are even (0, 2, ...): sample when CPHA=0, shift out when CPHA=1
                if (edges[0] == cpha) sh_rx <= {sh_rx[6:0], miso};
                else if (cpha) begin mosi <= sh_tx[7]; sh_tx <= {sh_tx[6:0], 1'b0}; end
                else begin sh_tx <= {sh_tx[6:0], 1'b0}; mosi <= sh_tx[6]; end
            end
        end else div <= div + 1'b1;
    end
endmodule

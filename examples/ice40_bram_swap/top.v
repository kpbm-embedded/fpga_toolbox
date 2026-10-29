// iCEBreaker: a 256 x 8 ROM in block RAM (initial content from rom.hex) is played out on the LEDs.
// icebram can later replace the ROM content inside the finished bitstream (no synthesis, no place and route),
// e.g. to update a soft-CPU firmware or a lookup table in seconds.
`default_nettype none
module top (input wire CLK, output wire LEDR_N, output wire LEDG_N, output wire [4:0] LED);
    reg [7:0] rom [0:255];
    initial $readmemh(`ROM_HEX, rom);
    reg [21:0] div = 0;
    reg [7:0]  addr = 0, q = 0;
    always @(posedge CLK) begin
        div <= div + 1'b1;
        if (&div) addr <= addr + 1'b1;
        q <= rom[addr];
    end
    assign {LEDR_N, LEDG_N} = ~q[7:6];
    assign LED = q[4:0];
endmodule

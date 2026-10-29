// iCEBreaker: 12 MHz oscillator -> PLL (icepll, 48 MHz) -> UART TX at 115200 baud on the FTDI channel B
// (pin 9 = FPGA TX), sending "hello from iCE40\r\n" twice a second. `pll` is written by icepll.
`default_nettype none
module top (input wire CLK, output wire TX, output wire LEDG_N);
    wire clk48, locked;
    pll u_pll (.clock_in(CLK), .clock_out(clk48), .locked(locked));
    reg [3:0] rst_cnt = 0;                      // hold reset until the PLL is locked for 15 clocks
    wire rst = ~&rst_cnt;
    always @(posedge clk48) if (!locked) rst_cnt <= 0; else if (rst) rst_cnt <= rst_cnt + 1'b1;

    localparam integer MSG_LEN = 18;
    reg [8*MSG_LEN-1:0] msg = "hello from iCE40\r\n";
    reg [4:0]  idx = 0;
    reg [23:0] gap = 0;                         // 2**23 / 48 MHz = 175 ms between messages
    reg        valid = 0;
    wire       ready;
    always @(posedge clk48) begin
        valid <= 1'b0;
        if (rst) begin idx <= 0; gap <= 0; end
        else if (idx == MSG_LEN) begin gap <= gap + 1'b1; if (&gap) idx <= 0; end
        else if (ready && !valid) begin valid <= 1'b1; idx <= idx + 1'b1; end
    end
    wire [7:0] ch = msg[8*(MSG_LEN-1-idx) +: 8];
    reg  [7:0] ch_q = 0;
    always @(posedge clk48) if (ready && !valid) ch_q <= ch;
    uart_tx #(.CLKS_PER_BIT(417)) u_tx (.clk(clk48), .rst, .data(ch_q), .valid, .ready, .tx(TX));   // 48e6 / 115200
    assign LEDG_N = ~locked;
endmodule

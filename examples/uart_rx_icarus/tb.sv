// Icarus testbench for uart_rx: 6 bytes, a glitch shorter than half a bit, a byte with a bad stop bit.
`timescale 1ns/1ps
module tb;
    localparam integer CPB = 16;
    reg clk = 0, rst = 1, rx = 1;
    wire [7:0] data; wire valid, frame_err;
    uart_rx #(.CLKS_PER_BIT(CPB)) dut (.clk, .rst, .rx, .data, .valid, .frame_err);
    always #5 clk = ~clk;
    byte got[$]; integer ferr = 0, errors = 0;
    always @(posedge clk) begin
        if (valid) got.push_back(data);
        if (frame_err) ferr = ferr + 1;
    end
    task automatic send(input [7:0] b, input stop);
        integer i;
        rx = 0; repeat (CPB) @(posedge clk);
        for (i = 0; i < 8; i = i + 1) begin rx = b[i]; repeat (CPB) @(posedge clk); end
        rx = stop; repeat (CPB) @(posedge clk);
        rx = 1; repeat (CPB) @(posedge clk);
    endtask
    byte msg[6] = '{8'h55, 8'hA5, 8'h00, 8'hFF, 8'h0D, 8'h42};
    initial begin
`ifdef VCD
        $dumpfile(`VCD); $dumpvars(0, tb);
`endif
        repeat (4) @(posedge clk); rst = 0; repeat (4) @(posedge clk);
        foreach (msg[k]) send(msg[k], 1);
        rx = 0; repeat (CPB / 4) @(posedge clk); rx = 1; repeat (3 * CPB) @(posedge clk);   // glitch
        send(8'h99, 0);                                                                    // bad stop bit
        repeat (4 * CPB) @(posedge clk);
        if (got.size() != 6) begin $display("FAIL: got %0d bytes, want 6", got.size()); errors++; end
        foreach (got[k]) if (got[k] !== msg[k]) begin $display("FAIL: byte %0d = %02h, want %02h", k, got[k], msg[k]); errors++; end
        if (ferr != 1) begin $display("FAIL: frame errors %0d, want 1", ferr); errors++; end
        $display("received %0d bytes, %0d framing error, glitch ignored", got.size(), ferr);
        if (errors == 0) $display("PASS uart_rx");
        else $fatal(1, "%0d errors", errors);
        $finish;
    end
endmodule

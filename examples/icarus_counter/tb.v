// Icarus Verilog testbench for counter: checks count, enable gating, clear and wrap.
`timescale 1ns/1ps
module tb;
    reg clk = 0, rst = 1, en = 0, clr = 0;
    wire [3:0] q; wire wrap;
    integer errors = 0, wraps = 0, i;
    counter #(.N(4)) dut (.clk(clk), .rst(rst), .en(en), .clr(clr), .q(q), .wrap(wrap));
    always #5 clk = ~clk;
    always @(posedge clk) if (wrap) wraps = wraps + 1;
    task check(input [3:0] want); begin
        if (q !== want) begin $display("FAIL q=%0d want %0d at %0t", q, want, $time); errors = errors + 1; end
    end endtask
    initial begin
        $dumpfile(`VCD); $dumpvars(0, tb);
        @(negedge clk); rst = 0; check(0);
        en = 1; for (i = 1; i <= 5; i = i + 1) begin @(negedge clk); check(i); end
        en = 0; repeat (3) @(negedge clk); check(5);              // enable gates counting
        en = 1; repeat (11) @(negedge clk); check(0);             // 5 + 11 = 16 -> wrapped
        clr = 1; @(negedge clk); clr = 0; check(0);
        if (wraps != 1) begin $display("FAIL wraps=%0d want 1", wraps); errors = errors + 1; end
        if (errors == 0) $display("PASS counter (4-bit, %0t ns)", $time);
        else $fatal(1, "%0d errors", errors);
        $finish;
    end
endmodule

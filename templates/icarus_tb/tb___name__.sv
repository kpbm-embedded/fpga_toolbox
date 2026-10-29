// Self-checking Icarus testbench for @NAME@: a reference model runs beside the DUT; $fatal on mismatch.
`timescale 1ns/1ps
module tb_@NAME@;
    reg clk = 0, rst = 1, en = 0, up = 1;
    wire [7:0] q;
    reg  [7:0] model = 0;
    integer i, errors = 0;
    @NAME@ dut (.clk, .rst, .en, .up, .q);
    always #5 clk = ~clk;
    initial begin
        $dumpfile("build/@NAME@.vcd"); $dumpvars(0, tb_@NAME@);
        repeat (2) @(posedge clk); rst = 0;
        for (i = 0; i < 1000; i = i + 1) begin
            @(negedge clk); en = $urandom % 4 != 0; up = $urandom % 3 != 0;
            @(posedge clk); #1;
            if (en) model = up ? model + 1 : model - 1;
            if (q !== model) begin errors = errors + 1; $display("cycle %0d: q=%0d model=%0d", i, q, model); end
        end
        if (errors) $fatal(1, "FAIL @NAME@: %0d errors", errors);
        $display("PASS @NAME@: 1000 random cycles");
        $finish;
    end
endmodule

// Random stimulus + functional cover points; run with coverage (make cover) to see what was never exercised.
`timescale 1ns/1ps
module tb_@NAME@;
    logic clk = 0, rst = 1, ped_req = 0;
    logic [1:0] light;
    logic walk;
    int reds = 0;
    @NAME@ dut (.*);
    always #5 clk = ~clk;
    c_yellow_to_red: cover property (@(posedge clk) light == 2'd1 ##1 light == 2'd2);
    c_walk:          cover property (@(posedge clk) walk);
    always @(posedge clk) if (light == 2'd2 && $past(light) == 2'd1) reds++;
    initial begin
        repeat (2) @(posedge clk); rst = 0;
        repeat (2000) begin @(negedge clk); ped_req = ($urandom_range(0, 15) == 0); end
        if (reds > 0) $display("PASS @NAME@: %0d pedestrian cycles", reds);
        else $fatal(1, "FAIL @NAME@: never turned red");
        $finish;
    end
endmodule

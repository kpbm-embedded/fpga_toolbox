// SystemVerilog testbench (Verilator --binary --timing): random valid/ready back-pressure, a scoreboard
// queue and a concurrent assertion (data stays stable while the output is stalled).
`timescale 1ns/1ps
module tb_@NAME@;
    logic clk = 0, rst = 1, in_valid = 0, out_ready = 0;
    logic [7:0] in_data = 0, out_data;
    logic in_ready, out_valid;
    logic [7:0] expected[$];
    int sent = 0, received = 0, errors = 0;
    @NAME@ dut (.*);
    always #5 clk = ~clk;
    a_stable: assert property (@(posedge clk) disable iff (rst) out_valid && !out_ready |=> out_valid && $stable(out_data))
        else errors++;
    always @(posedge clk) if (!rst) begin
        if (in_valid && in_ready) begin expected.push_back(in_data); sent++; end
        if (out_valid && out_ready) begin
            if (expected.size() == 0 || out_data != expected.pop_front()) errors++;
            received++;
        end
    end
    initial begin
        repeat (2) @(posedge clk); rst = 0;
        repeat (2000) begin
            @(negedge clk);
            if (!in_valid || in_ready) begin in_valid = 1'($urandom_range(0, 1)); in_data = 8'($urandom); end
            out_ready = $urandom_range(0, 3) != 0;
        end
        @(negedge clk); in_valid = 0; out_ready = 1; repeat (4) @(posedge clk);
        if (errors == 0 && sent == received && sent > 500) $display("PASS @NAME@: %0d transfers", sent);
        else $fatal(1, "FAIL @NAME@: sent %0d received %0d errors %0d", sent, received, errors);
        $finish;
    end
endmodule

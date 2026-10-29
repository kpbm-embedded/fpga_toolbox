// SystemVerilog testbench (Verilator --binary, timing enabled): measures the PWM duty over whole periods
// for 0 %, 1/256, 25 %, 50 %, 255/256 and checks that a duty change mid-period only takes effect at the
// next period (no glitch). A concurrent assertion watches the counter wrap.
`timescale 1ns/1ps
module tb;
    localparam int N = 8, P = 1 << N;
    logic clk = 0, rst = 1;
    logic [N-1:0] duty = '0;
    logic out, period_end;
    int errors = 0;
    pwm #(.N(N)) dut (.clk, .rst, .duty, .out, .period_end);
    always #5 clk = ~clk;

    a_wrap: assert property (@(posedge clk) disable iff (rst) period_end |=> (dut.cnt == '0))
        else begin $error("counter did not wrap"); errors++; end

    // high clocks in the next whole period (aligned to period_end)
    task automatic measure(output int high);
        high = 0;
        @(posedge clk iff period_end);
        repeat (P) begin @(posedge clk); #1 high += int'(out); end
    endtask

    initial begin
        int high;
        int unsigned tests[5] = '{0, 1, 64, 128, 255};
        if ($test$plusargs("vcd")) begin $dumpfile("pwm.vcd"); $dumpvars(0, tb); end
        repeat (3) @(posedge clk); rst = 0;
        foreach (tests[i]) begin
            duty = N'(tests[i]);
            @(posedge clk iff period_end);           // loaded at this period end
            measure(high);
            $display("duty %3d/256 -> high %3d clocks", tests[i], high);
            if (high != int'(tests[i])) begin $error("duty %0d measured %0d", tests[i], high); errors++; end
        end
        // glitch-free update: change duty in the middle of a period, that period keeps the old duty
        duty = 8'd200;
        @(posedge clk iff period_end);
        @(posedge clk iff period_end);
        repeat (P / 2) @(posedge clk);
        duty = 8'd10;
        high = 0;
        repeat (P / 2) begin @(posedge clk); #1 high += int'(out); end
        $display("mid-period change 200 -> 10: second half high %0d clocks (old duty kept)", high);
        if (high != 200 - P / 2) begin $error("glitch: %0d", high); errors++; end
        measure(high);
        if (high != 10) begin $error("new duty not applied: %0d", high); errors++; end
        if (errors == 0) $display("PASS pwm");
        else $display("FAIL pwm: %0d errors", errors);
        $finish;
    end
endmodule

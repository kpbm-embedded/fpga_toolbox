// Loopback testbench for @NAME@_tx -> @NAME@_rx at CLK_HZ / BAUD (Icarus or Verilator --binary).
`timescale 1ns/1ps
module tb_@NAME@;
    localparam int CLK_HZ = 12_000_000, BAUD = 115_200, CPB = CLK_HZ / BAUD;
    logic clk = 0, rst = 1, valid = 0;
    logic [7:0] data = 0, rx_data;
    logic ready, line, rx_valid, rx_err;
    logic [7:0] sent[$], got[$];
    int errors;
    @NAME@_tx #(.CLKS_PER_BIT(CPB)) u_tx (.clk, .rst, .data, .valid, .ready, .tx(line));
    @NAME@_rx #(.CLKS_PER_BIT(CPB)) u_rx (.clk, .rst, .rx(line), .data(rx_data), .valid(rx_valid), .frame_err(rx_err));
    always #(500_000_000.0 / CLK_HZ) clk = ~clk;
    always @(posedge clk) if (rx_valid) got.push_back(rx_data);
    initial begin
        repeat (4) @(posedge clk); rst = 0;
        for (int i = 0; i < 32; i++) begin
            @(posedge clk); while (!ready) @(posedge clk);
            data <= 8'($urandom); valid <= 1;
            @(posedge clk); sent.push_back(data); valid <= 0;
            @(posedge clk);
        end
        while (!ready) @(posedge clk); repeat (2 * CPB) @(posedge clk);
        errors = (got.size() == sent.size()) ? 0 : 1;
        foreach (sent[i]) if (i < got.size() && got[i] != sent[i]) errors++;
        if (errors == 0 && !rx_err) $display("PASS @NAME@: %0d bytes at %0d baud (%0d clocks per bit)", got.size(), BAUD, CPB);
        else $fatal(1, "FAIL @NAME@: sent %0d got %0d", sent.size(), got.size());
        $finish;
    end
endmodule

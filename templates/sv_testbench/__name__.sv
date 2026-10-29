// @NAME@: replace with your logic (template from fpga-box new sv_testbench). Example: valid/ready register slice.
module @NAME@ #(parameter int W = 8) (
    input  logic         clk,
    input  logic         rst,
    input  logic         in_valid,
    output logic         in_ready,
    input  logic [W-1:0] in_data,
    output logic         out_valid,
    input  logic         out_ready,
    output logic [W-1:0] out_data
);
    assign in_ready = !out_valid || out_ready;
    always_ff @(posedge clk)
        if (rst) out_valid <= 1'b0;
        else if (in_ready) begin out_valid <= in_valid; out_data <= in_data; end
endmodule

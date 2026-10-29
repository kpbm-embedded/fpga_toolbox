// @NAME@: replace with your logic (template from fpga-box new coverage_tb). Example: traffic-light FSM with
// a pedestrian request; the testbench measures line/toggle coverage and functional cover points.
module @NAME@ (
    input  logic clk,
    input  logic rst,
    input  logic ped_req,
    output logic [1:0] light,      // 0 green, 1 yellow, 2 red
    output logic walk
);
    typedef enum logic [1:0] {GREEN, YELLOW, RED} state_t;
    state_t st;
    logic [3:0] t;
    assign light = st;
    assign walk = (st == RED);
    always_ff @(posedge clk)
        if (rst) begin st <= GREEN; t <= '0; end
        else begin
            t <= t + 1'b1;
            unique case (st)
                GREEN:  if (ped_req && t >= 4'd5) begin st <= YELLOW; t <= '0; end
                YELLOW: if (t == 4'd2) begin st <= RED; t <= '0; end
                RED:    if (t == 4'd7) begin st <= GREEN; t <= '0; end
                default: st <= GREEN;
            endcase
        end
endmodule

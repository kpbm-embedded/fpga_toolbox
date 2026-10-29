// pwm: N-bit PWM, period 2**N clocks, out high for `duty` clocks of each period (duty = 0: always low,
// duty = 2**N - 1: high except one clock). The duty register loads at the end of a period, so a duty
// change never produces a short glitch pulse. `period_end` pulses on the last clock of each period.
`default_nettype none
module pwm #(parameter integer N = 8) (
    input  wire         clk,
    input  wire         rst,
    input  wire [N-1:0] duty,
    output reg          out,
    output wire         period_end
);
    reg [N-1:0] cnt, duty_q;
    assign period_end = (cnt == {N{1'b1}});
    always @(posedge clk) begin
        if (rst) begin cnt <= {N{1'b0}}; duty_q <= {N{1'b0}}; out <= 1'b0; end
        else begin
            cnt <= cnt + 1'b1;
            if (period_end) duty_q <= duty;
            out <= (period_end ? (duty != {N{1'b0}}) : ((cnt + 1'b1) < duty_q));
        end
    end
endmodule

// @NAME@: ULX3S (ECP5 LFE5U-85F, 25 MHz) top level (template from fpga-box new ecp5_project).
// Example: LED counter, button 1 (active high) reverses it. Replace with your logic.
`default_nettype none
module top (input wire clk_25mhz, input wire [6:0] btn, output wire [7:0] led, output wire wifi_gpio0);
    reg [26:0] cnt = 0;
    always @(posedge clk_25mhz) cnt <= btn[1] ? cnt - 1'b1 : cnt + 1'b1;
    assign led = cnt[26:19];
    assign wifi_gpio0 = 1'b1;     // keep the ESP32 on the ULX3S from resetting the FPGA
endmodule

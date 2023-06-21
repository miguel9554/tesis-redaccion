`timescale 1ns / 1ps

module adhoc_generator#(
    parameter WIDTH = 8
)(
    input clk, srst,
    input duty_inc_coarse, duty_inc_fine,
    input duty_dec_coarse, duty_dec_fine,
    input [WIDTH-1:0] duty_coarse, duty_fine, duty_nominal, div_value,
    output reg PWM
);

    reg [WIDTH-1:0] counter     = 'd0;
    reg [WIDTH-1:0] duty_cycle  = 'd0;
    wire n_PWM;

    assign n_PWM = counter < duty_cycle ? 'b1 : 'b0;

    always @(posedge clk) begin
        if (srst) begin
            duty_cycle  <= duty_nominal;
            counter     <= 'd0;
            PWM         <= 'd1;
        end
        else begin
            counter                              <= counter >= div_value-1 ? 'd0 : counter + 1;
            PWM                                  <= n_PWM;
            if      (duty_inc_coarse) duty_cycle <= duty_cycle + duty_coarse;
            else if (duty_inc_fine)   duty_cycle <= duty_cycle + duty_fine;
            else if (duty_dec_coarse) duty_cycle <= duty_cycle - duty_coarse;
            else if (duty_dec_fine)   duty_cycle <= duty_cycle - duty_fine;
        end
    end

endmodule

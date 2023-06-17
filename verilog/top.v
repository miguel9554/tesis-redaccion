`timescale 1ns / 1ps

module top(
    input clk,
    input btnU, btnD,
    input btnL, btnR,
    input [1:0] sw,
    output [1:0] led,
    output [0:0] JA
);

    wire duty_inc_coarse, duty_inc_fine, duty_dec_coarse, duty_dec_fine;

    localparam W = 8;
    reg [W-1:0] div_value = 'd10;
    reg [1:0] sw_old = 'd0;
    reg initialized = 'b0;
    reg [3:0] init_counter = 'b0;
    reg srst = 'b0;

    localparam real DUTY_CYCLE_NOMINAL = 0.5;
    localparam real DUTY_CYCLE_COARSE  = 0.1;
    localparam real DUTY_CYCLE_FINE    = 0.01;

    localparam integer DIV_VALUE_10MHZ = 10;
    localparam integer COUNTS_DUTY_NOMINAL_10MHZ    = DUTY_CYCLE_NOMINAL*DIV_VALUE_10MHZ;
    localparam integer COUNTS_DUTY_COARSE_10MHZ     = DUTY_CYCLE_COARSE *DIV_VALUE_10MHZ;
    localparam integer COUNTS_DUTY_FINE_10MHZ       = DUTY_CYCLE_FINE   *DIV_VALUE_10MHZ;

    localparam integer DIV_VALUE_5MHZ = 20;
    localparam integer COUNTS_DUTY_NOMINAL_5MHZ    = DUTY_CYCLE_NOMINAL*DIV_VALUE_5MHZ;
    localparam integer COUNTS_DUTY_COARSE_5MHZ     = DUTY_CYCLE_COARSE *DIV_VALUE_5MHZ;
    localparam integer COUNTS_DUTY_FINE_5MHZ       = 'd1;

    localparam integer DIV_VALUE_1MHZ = 100;
    localparam integer COUNTS_DUTY_NOMINAL_1MHZ    = DUTY_CYCLE_NOMINAL*DIV_VALUE_1MHZ;
    localparam integer COUNTS_DUTY_COARSE_1MHZ     = DUTY_CYCLE_COARSE *DIV_VALUE_1MHZ;
    localparam integer COUNTS_DUTY_FINE_1MHZ       = DUTY_CYCLE_FINE   *DIV_VALUE_1MHZ;

    reg [W-1:0] div_value_curr,
                counts_duty_nominal_curr,
                counts_duty_coarse_curr,
                counts_duty_fine_curr;

     always @(posedge clk) begin
        if (sw[1]) begin
            div_value_curr              <= DIV_VALUE_1MHZ;
            counts_duty_nominal_curr    <= COUNTS_DUTY_NOMINAL_1MHZ;
            counts_duty_coarse_curr     <= COUNTS_DUTY_COARSE_1MHZ;
            counts_duty_fine_curr       <= COUNTS_DUTY_FINE_1MHZ;
        end
        else if (sw[0]) begin
            div_value_curr              <= DIV_VALUE_5MHZ;
            counts_duty_nominal_curr    <= COUNTS_DUTY_NOMINAL_5MHZ;
            counts_duty_coarse_curr     <= COUNTS_DUTY_COARSE_5MHZ;
            counts_duty_fine_curr       <= COUNTS_DUTY_FINE_5MHZ;
        end
        else begin
            div_value_curr              <= DIV_VALUE_10MHZ;
            counts_duty_nominal_curr    <= COUNTS_DUTY_NOMINAL_10MHZ;
            counts_duty_coarse_curr     <= COUNTS_DUTY_COARSE_10MHZ;
            counts_duty_fine_curr       <= COUNTS_DUTY_FINE_10MHZ;
        end
        sw_old <= sw;
     end

     always @(posedge clk) begin
        if (initialized == 'b0) begin
            if (init_counter < 'd14) begin
                init_counter <= init_counter+1;
            end
            else begin
                initialized <= 'b1;
                srst <= 'b1;
            end
        end
        else begin
            if (sw_old != sw) srst <= 'b1;
        end
        if (srst) srst <= 'b0;
     end


    // debounce of buttons
     debounce u_debounce_inc_coarse(clk,btnU,duty_inc_coarse);
     debounce u_debounce_dec_coarse(clk,btnD,duty_dec_coarse);
     debounce u_debounce_inc_fine(clk,btnR,duty_inc_fine);
     debounce u_debounce_dec_fine(clk,btnL,duty_dec_fine);

    // PWM generator
    adhoc_generator#(.WIDTH(W))u_generator(
        .clk(clk),
        .srst(srst),
        .duty_coarse(counts_duty_coarse_curr),
        .duty_fine(counts_duty_fine_curr),
        .duty_nominal(counts_duty_nominal_curr),
        .div_value(div_value_curr),
        .duty_inc_coarse(duty_inc_coarse),
        .duty_inc_fine(duty_inc_fine),
        .duty_dec_coarse(duty_dec_coarse),
        .duty_dec_fine(duty_dec_fine),
        .PWM(JA[0])
    );

    assign led = sw;

endmodule

module debounce(
    input clk,
    input data_in,
    output data_out
);
    localparam DEBOUNCE_BITS = 23;

    reg [DEBOUNCE_BITS-1:0] debounce_counter;
    wire debounce_enable;
    wire tmp_1, tmp_2;

    // debounce enable generation, has period T_clk/2**DEBOUNCE_BITS
    always @(posedge clk) debounce_counter = debounce_counter + 'b1;
    assign debounce_enable = debounce_counter == 2**DEBOUNCE_BITS-1 ? 'b1 : 'b0;

    // debounce of buttons
     DFF u_DFF_inc_coarse(clk,debounce_enable,data_in,tmp_1);
     DFF u_DFF_dec_coarse(clk,debounce_enable,tmp_1,tmp_2);

     assign data_out = tmp_1 & (~ tmp_2) & debounce_enable;

endmodule

module DFF(
    input clk,
    input en,
    input D,
    output reg Q
);
    always @(posedge clk) begin
        if (en) Q <= D;
    end
endmodule

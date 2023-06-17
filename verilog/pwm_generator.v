module pwm_generator(
    input clk,           // 100MHz clock input
    input increase_duty, // input to increase 10% duty cycle
    input decrease_duty, // input to decrease 10% duty cycle
    output PWM_OUT
);

    localparam DEBOUNCE_COUNT = 25_000_000;

    wire slow_clk_enable;           // slow clock enable signal for debouncing FFs
    reg[27:0] counter_debounce=0;   // counter for creating slow clock enable signals
    wire tmp1,tmp2,duty_inc;        // temporary flip-flop signals for debouncing the increasing button
    wire tmp3,tmp4,duty_dec;        // temporary flip-flop signals for debouncing the decreasing button
    reg[3:0] counter_PWM=0;         // counter for creating 10Mhz PWM signal
    reg[3:0] DUTY_CYCLE=5;          // initial duty cycle is 50%

    always @(posedge clk) begin
        counter_debounce <= counter_debounce + 1;
        if(counter_debounce>=DEBOUNCE_COUNT) counter_debounce <= 0;
    end

    assign slow_clk_enable = counter_debounce == DEBOUNCE_COUNT ?1:0;

    // debouncing FFs for increasing button
    DFF_PWM PWM_DFF1(clk,slow_clk_enable,increase_duty,tmp1);
    DFF_PWM PWM_DFF2(clk,slow_clk_enable,tmp1, tmp2);
    assign duty_inc =  tmp1 & (~ tmp2) & slow_clk_enable;

    // debouncing FFs for decreasing button
    DFF_PWM PWM_DFF3(clk,slow_clk_enable,decrease_duty, tmp3);
    DFF_PWM PWM_DFF4(clk,slow_clk_enable,tmp3, tmp4);
    assign duty_dec =  tmp3 & (~ tmp4) & slow_clk_enable;

    // vary the duty cycle using the debounced buttons above
    always @(posedge clk) begin
        if (duty_inc==1 && DUTY_CYCLE <= 9)    DUTY_CYCLE <= DUTY_CYCLE + 1;
        else if (duty_dec==1 && DUTY_CYCLE>=1) DUTY_CYCLE <= DUTY_CYCLE - 1;
    end

    // Create 10MHz PWM signal with variable duty cycle controlled by 2 buttons
    always @(posedge clk) begin
        counter_PWM <= counter_PWM + 1;
        if (counter_PWM>=9) counter_PWM <= 0;
    end

    assign PWM_OUT = counter_PWM < DUTY_CYCLE ? 1 : 0;

endmodule

// Debouncing DFFs for push buttons on FPGA
module DFF_PWM(
    input clk,
    input en,
    input D,
    output reg Q
);
    always @(posedge clk) begin
        if (en) Q <= D;
    end
endmodule

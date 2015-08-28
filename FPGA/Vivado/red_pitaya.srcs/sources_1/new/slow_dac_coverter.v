/**
 * @brief Module converts 12 bit user input into 24 bit PWM format
 *
 * @Author Lewis Woolfson
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */

module slow_dac_converter
(  
    input clk_i     ,
    input rstn_i    ,
    //data 
    input [12-1:0] dat_i    ,
    output reg [24-1:0] dat_o
);

// 156 corresponds to 100% duty cycle (from first 8 bits)
localparam PWM_MAX = 156; 

reg [8-1:0] a;
reg [16-1:0] b;
reg [8-1:0] c;
reg [8-1:0] d;

 always @(posedge clk_i) begin
    if(rstn_i == 1'b0) begin
        dat_o <= 24'd0;
    end else begin
         // dat_o[24-1: 16] <= dat_i[12-1:4]; // 8 MSB are as they are 
        
        // if the first bit is 1 then it's negative, otherwise it is a positive number
        /*
             Mapping ADC Cnts (pid_out) --> Duty Cycle
            -2048 cnts --> 0%
            0 cnts --> 50%
            +2047 cnts --> 100%
            
            Transformation for x adc counts is ((x +- 128)/255)*156
            We approximate the division as x/255 ~= x/256 + x/65536 
            We carry out the division (by factors of 2) using bit shifts as it executes fast in hardware  
        */
       
        if(dat_i[12-1:12-2] == 1'b1) begin // negative number
            a <= dat_i[12-1:4] - 8'd128;
        end else begin // positive number
            a <= dat_i[12-1:4] + 8'd128;         
        end
        
          b <= a * 8'd156;
          c <= b >> 8;
          d <= b >> 16; // always 0?
          dat_o[24-1:16] <= c + d;
          
        case (dat_i[4-1:0])
            // PWM clock - fine resolution
            4'd0 : dat_o[15:0] <= 16'b0000000000000000; // low duty cycle
            4'd1 : dat_o[15:0] <= 16'b0000000000000001;
            4'd2 : dat_o[15:0] <= 16'b0000000100000001;
            4'd3 : dat_o[15:0] <= 16'b0000100000100001;
            4'd4 : dat_o[15:0] <= 16'b0001000100010001;
            4'd5 : dat_o[15:0] <= 16'b0010010010010001;
            4'd6 : dat_o[15:0] <= 16'b0010100100101001;
            4'd7 : dat_o[15:0] <= 16'b0101010010101001;
            4'd8 : dat_o[15:0] <= 16'b0101010101010101;
            4'd9 : dat_o[15:0] <= 16'b1010101101010110;
            4'd10: dat_o[15:0] <= 16'b1101011011010110;
            4'd11: dat_o[15:0] <= 16'b1101101101101110;
            4'd12: dat_o[15:0] <= 16'b1110111011101110;
            4'd13: dat_o[15:0] <= 16'b1111011111011110;
            4'd14: dat_o[15:0] <= 16'b1111111011111110;
            4'd15: dat_o[15:0] <= 16'b1111111111111110; //higher duty cycle
        endcase 
    end
 end   
    
endmodule

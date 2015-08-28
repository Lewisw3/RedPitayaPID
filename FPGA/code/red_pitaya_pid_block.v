
/**
Title: Red Pitaya PID Controller 
Author: Lewis Woolfson
Date: 28/08/2015
(Based upon original Red Pitaya PID Controller by Matej Oblak)
*/

/**
 * GENERAL DESCRIPTION:
 *
 * Proportional-integral-derivative (PID) controller.
 *
 *
 *        /---\         /---\      /-----------\
 *   IN --| - |----+--> | P | ---> | SUM & SAT | ---> OUT
 *        \---/    |    \---/      \-----------/
 *          ^      |                   ^  ^
 *          |      |    /---\          |  |
 *   set ----      +--> | I | ---------   |
 *   point         |    \---/             |
 *                 |                      |
 *                 |    /---\             |
 *                 ---> | D | ------------
 *                      \---/
 *
 *
 * Proportional-integral-derivative (PID) controller is made from three parts. 
 *
 * Error which is difference between set point and input signal is driven into
 * propotional, integral and derivative part. Each calculates its own value which
 * is then summed and saturated before given to output.
 *
 * Additional Features:
 *  - An acceptable absolute tolerance is included for the calculation of the error term
 *  - Sample and hold capability is included for integration term
 *  - Integrator reset is included
 *  - User defined lock divider has been implemented for the integrator term
 */ 



module red_pitaya_pid_block #(
   parameter	 adc_res = 14 			// ADC resolution
)
(
   // data  
   input clk_i,  // clock
   input rstn_i,  // reset - active low
   input [adc_res-1:0] dat_i ,  // input data
   output [adc_res-1:0] dat_o,  // output data  

   // PID parameters 
   input [adc_res-1:0] set_sp_i, // set point
   input [adc_res-1:0] set_kp_i, // Kp
   input [adc_res-1:0] set_ki_i, // Ki
   input [adc_res-1:0] set_kd_i, // Kd
   input int_rst_i, // integrator reset
   input int_hold , // sample and hold
   
   // advanced parameters
   input [5-1:0] PSR,  // Proportional Signal Resolution
   input [5-1:0] ISR,  // Integral Signal Resolution
   input [5-1:0] DSR,  // Derivative Signal Resolution
   input [30-1:0]ICD,  // Integral Clock Divider
   input [9-1:0] TOL   // Tolerance 
);



//---------------------------------------------------------------------------------
//  Set point error calculation
//---------------------------------------------------------------------------------



localparam MAXWIDTH = adc_res*2 + 1;

reg  [ (adc_res+1)-1: 0] error        ;
reg  [ (adc_res+1)-1: 0] err_temp        ;
reg  [ (adc_res+1)-1: 0] abs_temp        ;

always @(posedge clk_i) begin
	if (rstn_i == 1'b0) begin
		error <= {adc_res+1{1'b0}};	
   end else begin
        err_temp <= $signed(set_sp_i) - $signed(dat_i)  ;
        abs_temp <= ($signed(err_temp) < 0) ? -$signed(err_temp) : err_temp;
        error <= (abs_temp < TOL) ? {adc_res+1{1'b0}} : err_temp;
    end
end




//---------------------------------------------------------------------------------
//  Proportional Term
//---------------------------------------------------------------------------------



reg   [    MAXWIDTH-1: 0] kp_reg        ;
wire  [    MAXWIDTH-1: 0] kp_mult       ;

always @(posedge clk_i) begin
   if (rstn_i == 1'b0) begin
      kp_reg  <= {MAXWIDTH{1'b0}};
   end else begin
       // set the proportional term resolution i.e. the number of bits to include in the final PID summation
      case (PSR)
          5'd5:    kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{5{1'b1}}, {kp_mult[MAXWIDTH-1:5]}} : {{5{1'b0}}, {kp_mult[MAXWIDTH-1:5]}} ;   
          5'd6:    kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{6{1'b1}}, {kp_mult[MAXWIDTH-1:6]}} : {{6{1'b0}}, {kp_mult[MAXWIDTH-1:6]}} ;   
          5'd7:    kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{7{1'b1}}, {kp_mult[MAXWIDTH-1:7]}} : {{7{1'b0}}, {kp_mult[MAXWIDTH-1:7]}} ;
          5'd8:    kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{8{1'b1}}, {kp_mult[MAXWIDTH-1:8]}} : {{8{1'b0}}, {kp_mult[MAXWIDTH-1:8]}} ;  
          5'd9:    kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{9{1'b1}}, {kp_mult[MAXWIDTH-1:9]}} : {{9{1'b0}}, {kp_mult[MAXWIDTH-1:9]}} ;   
          5'd10:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{10{1'b1}}, {kp_mult[MAXWIDTH-1:10]}} : {{10{1'b0}}, {kp_mult[MAXWIDTH-1:10]}} ;  
          5'd11:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{11{1'b1}}, {kp_mult[MAXWIDTH-1:11]}} : {{11{1'b0}}, {kp_mult[MAXWIDTH-1:11]}} ;   
          5'd12:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{12{1'b1}}, {kp_mult[MAXWIDTH-1:12]}} : {{12{1'b0}}, {kp_mult[MAXWIDTH-1:12]}} ;    
          5'd13:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{13{1'b1}}, {kp_mult[MAXWIDTH-1:13]}} : {{13{1'b0}}, {kp_mult[MAXWIDTH-1:13]}} ;   
          5'd14:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{14{1'b1}}, {kp_mult[MAXWIDTH-1:14]}} : {{14{1'b0}}, {kp_mult[MAXWIDTH-1:14]}} ;   
          5'd15:   kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{15{1'b1}}, {kp_mult[MAXWIDTH-1:15]}} : {{15{1'b0}}, {kp_mult[MAXWIDTH-1:15]}} ;        
          default:       kp_reg <= (kp_mult[MAXWIDTH-1] == 1'b1) ? {{12{1'b1}}, {kp_mult[MAXWIDTH-1:12]}} : {{12{1'b0}}, {kp_mult[MAXWIDTH-1:12]}} ;
     endcase       
   end
end

assign kp_mult = $signed(error) * $signed(set_kp_i); 



//---------------------------------------------------------------------------------
//  Integration Term
//---------------------------------------------------------------------------------




reg  [29-1: 0] ki_mult; 
wire [33-1: 0] int_sum;	
reg  [32-1: 0] int_reg;	
reg  [32-1: 0] int_shr;  
reg  [27-1: 0] counter;

always @(posedge clk_i) begin

   if (rstn_i == 1'b0) begin
      ki_mult <= {29{1'b0}};
      int_reg <= {32{1'b0}};
      counter <= {27{1'b0}};
   end else begin
       
      counter = (counter >= $unsigned(ICD)) ? 27'h0 : counter + 27'h1;

      if (int_rst_i) begin // integrator reset
        
         ki_mult <=  $signed(error) * $signed(set_ki_i)  ;
         int_reg <= 32'h0;
    
      end else if(int_hold) begin // integrator sample-and-hold
        
         ki_mult <= {29{1'b0}};
         int_reg <= int_reg[32-1:0];
           
      end else if(counter != ICD) begin // integrator clock division
        
           ki_mult <=  $signed(error) * $signed(set_ki_i)  ;
           int_reg <= int_reg[32-1:0]; // use reg as it is
           
      end else if (int_sum[33-1:33-2] == 2'b01) begin // positive saturation
      
         ki_mult <=  $signed(error) * $signed(set_ki_i)  ;
         int_reg <= 32'h7FFFFFFF; // max positive     
            
      end else if (int_sum[33-1:33-2] == 2'b10) begin // negative saturation  
        
         ki_mult <=  $signed(error) * $signed(set_ki_i)  ;
         int_reg <= 32'h80000000; // max negative   
         
      end else begin 
      
         ki_mult <=  $signed(error) * $signed(set_ki_i)  ;
         int_reg <= int_sum[32-1:0]; // use sum as it is
         
      end
   end
end

assign int_sum = $signed(ki_mult) + $signed(int_reg) ;

always @(posedge clk_i) begin
    // integral term resolution
    case (ISR)
          5'd14:   int_shr <= (int_reg[32-1] == 1'b1) ? {{14{1'b1}}, {int_reg[32-1:14]}} : {{14{1'b0}}, {int_reg[32-1:14]}};   
          5'd15:   int_shr <= (int_reg[32-1] == 1'b1) ? {{15{1'b1}}, {int_reg[32-1:15]}} : {{15{1'b0}}, {int_reg[32-1:15]}};     
          5'd16:   int_shr <= (int_reg[32-1] == 1'b1) ? {{16{1'b1}}, {int_reg[32-1:16]}} : {{16{1'b0}}, {int_reg[32-1:16]}}; 
          5'd17:   int_shr <= (int_reg[32-1] == 1'b1) ? {{17{1'b1}}, {int_reg[32-1:17]}} : {{17{1'b0}}, {int_reg[32-1:17]}};   
          5'd18:   int_shr <= (int_reg[32-1] == 1'b1) ? {{18{1'b1}}, {int_reg[32-1:18]}} : {{18{1'b0}}, {int_reg[32-1:18]}};  
          5'd19:   int_shr <= (int_reg[32-1] == 1'b1) ? {{19{1'b1}}, {int_reg[32-1:19]}} : {{19{1'b0}}, {int_reg[32-1:19]}};  
          5'd20:   int_shr <= (int_reg[32-1] == 1'b1) ? {{20{1'b1}}, {int_reg[32-1:20]}} : {{20{1'b0}}, {int_reg[32-1:20]}};  
          5'd21:   int_shr <= (int_reg[32-1] == 1'b1) ? {{21{1'b1}}, {int_reg[32-1:21]}} : {{21{1'b0}}, {int_reg[32-1:21]}}; 
          5'd22:   int_shr <= (int_reg[32-1] == 1'b1) ? {{22{1'b1}}, {int_reg[32-1:22]}} : {{22{1'b0}}, {int_reg[32-1:22]}};   
          5'd23:   int_shr <= (int_reg[32-1] == 1'b1) ? {{23{1'b1}}, {int_reg[32-1:23]}} : {{23{1'b0}}, {int_reg[32-1:23]}};       
          5'd24:   int_shr <= (int_reg[32-1] == 1'b1) ? {{24{1'b1}}, {int_reg[32-1:24]}} : {{24{1'b0}}, {int_reg[32-1:24]}};        
          default: int_shr <= (int_reg[32-1] == 1'b1) ? {{18{1'b1}}, {int_reg[32-1:18]}} : {{18{1'b0}}, {int_reg[32-1:18]}}; 
   endcase       
end




//---------------------------------------------------------------------------------
//  Derivative Term
//---------------------------------------------------------------------------------



wire  [MAXWIDTH-1: 0] kd_mult;
reg   [MAXWIDTH-1: 0] kd_reg;
reg   [MAXWIDTH-1: 0] kd_reg_r;
reg   [MAXWIDTH  : 0] kd_reg_s;

always @(posedge clk_i) begin
   if (rstn_i == 1'b0) begin
      kd_reg   <= {MAXWIDTH{1'b0}};
      kd_reg_r <= {MAXWIDTH{1'b0}};
      kd_reg_s <= {MAXWIDTH+1{1'b0}};
   end
   else begin
       // derivative term resolution
       case (DSR)
               5'd3:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{3{1'b1}}, {kd_mult[MAXWIDTH-1:3]}} : {{3{1'b0}}, {kd_mult[MAXWIDTH-1:3]}} ; 
               5'd4:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{4{1'b1}}, {kd_mult[MAXWIDTH-1:4]}} : {{4{1'b0}}, {kd_mult[MAXWIDTH-1:4]}} ; 
               5'd5:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{5{1'b1}}, {kd_mult[MAXWIDTH-1:5]}} : {{5{1'b0}}, {kd_mult[MAXWIDTH-1:5]}} ;  
               5'd6:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{6{1'b1}}, {kd_mult[MAXWIDTH-1:6]}} : {{6{1'b0}}, {kd_mult[MAXWIDTH-1:6]}} ;   
               5'd7:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{7{1'b1}}, {kd_mult[MAXWIDTH-1:7]}} : {{7{1'b0}}, {kd_mult[MAXWIDTH-1:7]}} ; 
               5'd8:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{8{1'b1}}, {kd_mult[MAXWIDTH-1:8]}} : {{8{1'b0}}, {kd_mult[MAXWIDTH-1:8]}} ; 
               5'd9:    kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{9{1'b1}}, {kd_mult[MAXWIDTH-1:9]}} : {{9{1'b0}}, {kd_mult[MAXWIDTH-1:9]}} ;    
               5'd10:   kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{10{1'b1}}, {kd_mult[MAXWIDTH-1:10]}} : {{10{1'b0}}, {kd_mult[MAXWIDTH-1:10]}} ;   
               5'd11:   kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{11{1'b1}}, {kd_mult[MAXWIDTH-1:11]}} : {{11{1'b0}}, {kd_mult[MAXWIDTH-1:11]}} ;  
               5'd12:   kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{12{1'b1}}, {kd_mult[MAXWIDTH-1:12]}} : {{12{1'b0}}, {kd_mult[MAXWIDTH-1:12]}} ;   
               5'd13:   kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{13{1'b1}}, {kd_mult[MAXWIDTH-1:13]}} : {{13{1'b0}}, {kd_mult[MAXWIDTH-1:13]}} ;  
               default:  kd_reg <= (kd_mult[MAXWIDTH-1] == 1'b1) ? {{10{1'b1}}, {kd_mult[MAXWIDTH-1:10]}} : {{10{1'b0}}, {kd_mult[MAXWIDTH-1:10]}} ;   
      endcase       
          
      kd_reg_r <= kd_reg;
      kd_reg_s <=  $signed(kd_reg) - $signed(kd_reg_r);
   end
end

assign kd_mult = $signed(error) * $signed(set_kd_i) ;



//---------------------------------------------------------------------------------
//  Summation and Saturation 
//---------------------------------------------------------------------------------


wire  [   33-1: 0] pid_sum     ; 
reg   [   adc_res-1: 0] pid_out     ;
reg int_rst;
always @(posedge clk_i) begin

    if (rstn_i == 1'b0) begin
          pid_out  <= {adc_res{1'b0}} ; 
    end else begin
    
        if(adc_res == 14) begin // fast adc (14 bit)
         
              if ({pid_sum[33-1],|pid_sum[32-2:13]} == 2'b01)  begin //positive overflow
                    pid_out <= 14'h1FFF ; 
              end else if ({pid_sum[33-1],&pid_sum[33-2:13]} == 2'b10) begin //negative overflow      	
                    pid_out <= 14'h2000 ; 
             end else begin
                    pid_out <= pid_sum[14-1:0] ;
              end
                        
         end else if(adc_res == 12) begin // slow adc (12 bit)
                
              if ({pid_sum[33-1],|pid_sum[32-2:11]} == 2'b01)  begin //positive overflow
                    pid_out <= 12'h7FF ;
              end else if ({pid_sum[33-1],&pid_sum[33-2:11]} == 2'b10) begin //negative overflow  
                    pid_out <= 12'h800 ; 
              end else begin                
                    pid_out <= pid_sum[12-1:0] ;
              end
           
         end     
    end 
end

assign pid_sum = $signed(kp_reg) + $signed(int_shr) + $signed(kd_reg_s) ;
assign dat_o = pid_out ;
 


endmodule
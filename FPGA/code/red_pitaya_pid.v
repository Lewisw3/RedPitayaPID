
/**
Title: Red Pitaya PID Controller 
Author: Lewis Woolfson
Date: 28/08/2015
(Based upon original Red Pitaya PID Controller by Matej Oblak)
*/



/**
 * GENERAL DESCRIPTION:
 *
 * Multiple channel PID controller
 *
 * Fast Analog Interface operates a 2x2 MIMO PID Controller
 * Slow Analog Extension Interface operates a 4-channel SISO PID Controller 
 *
 *                     MIMO CONFIGURATION
 
 *                 /-------\       /-----------\
 *   CHA -----+--> | PID11 | ------| SUM & SAT | ---> CHA
 *            |    \-------/       \-----------/
 *            |                            ^
 *            |    /-------\               |
 *            ---> | PID21 | ----------    |
 *                 \-------/           |   |
 *                                     |   |
 *  INPUT                              |   |         OUTPUT
 *                                     |   |
 *                 /-------\           |   |
 *            ---> | PID12 | --------------
 *            |    \-------/           |    
 *            |                        ÿ
 *            |    /-------\       /-----------\
 *   CHB -----+--> | PID22 | ------| SUM & SAT | ---> CHB
 *                 \-------/       \-----------/
 *
 *
 *                  SISO CONFIGURATION (n = 0,1,2,3)
 *
 *                 /-------\       /-----------\
 *   IN -----+--> | PID n  |------ | SUM & SAT | ---> out
 *                 \-------/       \-----------/
 *
 * MIMO controller is build from four equal submodules, each can have 
 * different settings.
 *
 * Each output is sum of two controllers with different input. That sum is also
 * saturated to protect from wrapping.
 *
 * The SISO controllers operate independently and are also saturated
 * 
 */



module red_pitaya_pid
(
  
   input                 clk_i           ,  //!< processing clock
   input                 rstn_i          ,  //!< processing reset - active low
   
   // signals fast ADC
   input      [ 14-1: 0] dat_a_i         ,  //!< input data CHA
   input      [ 14-1: 0] dat_b_i         ,  //!< input data CHB
   output     [ 14-1: 0] dat_a_o         ,  //!< output data CHA
   output     [ 14-1: 0] dat_b_o         ,  //!< output data CHB

  // signal slow ADC
  input   [ 12-1: 0] adc_slx_a_i        ,  //!< Slow ADC CHA input
  input   [ 12-1: 0] adc_slx_b_i        ,  //!< Slow ADC CHB input 
  input   [ 12-1: 0] adc_slx_c_i        ,  //!< Slow ADC CHC input 
  input   [ 12-1: 0] adc_slx_d_i        ,  //!< Slow ADC CHD input

  output    [ 24-1: 0] dac_pwm_a_o        ,  //!< DAC PWM CHA output
  output    [ 24-1: 0] dac_pwm_b_o        ,  //!< DAC PWM CHB output
  output    [ 24-1: 0] dac_pwm_c_o        ,  //!< DAC PWM CHC output
  output    [ 24-1: 0] dac_pwm_d_o        ,  //!< DAC PWM CHD output
  
  // DIO_P pins
  input [ 8-1: 0] int_hold_pins       , // 1- high, 0 low for DIOn_P pins where n is from 0 to 7
  
  //LEDS
  output  [8-1: 0] led,
  
   // system bus
   input                 sys_clk_i       ,  //!< bus clock
   input                 sys_rstn_i      ,  //!< bus reset - active low
   input      [ 32-1: 0] sys_addr_i      ,  //!< bus address
   input      [ 32-1: 0] sys_wdata_i     ,  //!< bus write data
   input      [  4-1: 0] sys_sel_i       ,  //!< bus write byte select
   input                 sys_wen_i       ,  //!< bus write enable
   input                 sys_ren_i       ,  //!< bus read enable
   output     [ 32-1: 0] sys_rdata_o     ,  //!< bus read data
   output                sys_err_o       ,  //!< bus error indicator
   output                sys_ack_o          //!< bus acknowledge signal
);


wire [ 32-1: 0] addr         ;
wire [ 32-1: 0] wdata        ;
wire            wen          ;
wire            ren          ;
reg  [ 32-1: 0] rdata        ;
reg             err          ;
reg             ack          ;


localparam  adc_res_fast = 14     ;
localparam  adc_res_slow = 12    ;



//---------------------------------------------------------------------------------
//  PID FAST 11
//---------------------------------------------------------------------------------

wire [ 14-1: 0] pid_11_out   ;
reg  [ 14-1: 0] set_11_sp    ;
reg  [ 14-1: 0] set_11_kp    ;
reg  [ 14-1: 0] set_11_ki    ;
reg  [ 14-1: 0] set_11_kd    ;
reg             set_11_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_11           ;
reg [5-1:0] ISR_11           ;
reg [5-1:0] DSR_11           ;
reg [30-1:0] ICD_11          ;
reg [9-1:0] TOL_11           ;


red_pitaya_pid_block #(
  .adc_res (  adc_res_fast  ) 
)
i_pid11
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  dat_a_i        ),  // input data
  .dat_o        (  pid_11_out     ),  // output data

   // settings
  .set_sp_i     (  set_11_sp      ),  // set point
  .set_kp_i     (  set_11_kp      ),  // Kp
  .set_ki_i     (  set_11_ki      ),  // Ki
  .set_kd_i     (  set_11_kd      ),  // Kd
  .int_rst_i    (  set_11_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[0]  ),
  
  // advanced parameters
  .PSR     (  PSR_11      ),  
  .ISR     (  ISR_11      ),
  .DSR     (  DSR_11      ),  
  .ICD     (  ICD_11      ),
  .TOL     (  TOL_11      )  
);


//---------------------------------------------------------------------------------
//  PID FAST 21
//---------------------------------------------------------------------------------

wire [ 14-1: 0] pid_21_out   ;
reg  [ 14-1: 0] set_21_sp    ;
reg  [ 14-1: 0] set_21_kp    ;
reg  [ 14-1: 0] set_21_ki    ;
reg  [ 14-1: 0] set_21_kd    ;
reg             set_21_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_21           ;
reg [5-1:0] ISR_21           ;
reg [5-1:0] DSR_21           ;
reg [30-1:0] ICD_21           ;
reg [9-1:0] TOL_21           ;

red_pitaya_pid_block #(
.adc_res (  adc_res_fast  ) 
)
i_pid21
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  dat_a_i        ),  // input data
  .dat_o        (  pid_21_out     ),  // output data

   // settings
  .set_sp_i     (  set_21_sp      ),  // set point
  .set_kp_i     (  set_21_kp      ),  // Kp
  .set_ki_i     (  set_21_ki      ),  // Ki
  .set_kd_i     (  set_21_kd      ),  // Kd
  .int_rst_i    (  set_21_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[1]  ),
  
    // advanced parameters
  .PSR     (  PSR_21      ),  
  .ISR     (  ISR_21      ),
  .DSR     (  DSR_21      ),  
  .ICD     (  ICD_21      ),
  .TOL     (  TOL_21      ) 
);


//---------------------------------------------------------------------------------
//  PID FAST 12
//---------------------------------------------------------------------------------

wire [ 14-1: 0] pid_12_out   ;
reg  [ 14-1: 0] set_12_sp    ;
reg  [ 14-1: 0] set_12_kp    ;
reg  [ 14-1: 0] set_12_ki    ;
reg  [ 14-1: 0] set_12_kd    ;
reg             set_12_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_12           ;
reg [5-1:0] ISR_12           ;
reg [5-1:0] DSR_12           ;
reg [30-1:0] ICD_12           ;
reg [9-1:0] TOL_12           ;

red_pitaya_pid_block #(
.adc_res (  adc_res_fast  )    
)
i_pid12
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  dat_b_i        ),  // input data
  .dat_o        (  pid_12_out     ),  // output data

   // settings
  .set_sp_i     (  set_12_sp      ),  // set point
  .set_kp_i     (  set_12_kp      ),  // Kp
  .set_ki_i     (  set_12_ki      ),  // Ki
  .set_kd_i     (  set_12_kd      ),  // Kd
  .int_rst_i    (  set_12_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[2]  ),
    
   // advanced parameters
  .PSR     (  PSR_12      ),  
  .ISR     (  ISR_12      ),
  .DSR     (  DSR_12      ),  
  .ICD     (  ICD_12      ),
  .TOL     (  TOL_12      )    
);

//---------------------------------------------------------------------------------
//  PID FAST 22
//---------------------------------------------------------------------------------


wire [ 14-1: 0] pid_22_out   ;
reg  [ 14-1: 0] set_22_sp    ;
reg  [ 14-1: 0] set_22_kp    ;
reg  [ 14-1: 0] set_22_ki    ;
reg  [ 14-1: 0] set_22_kd    ;
reg             set_22_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_22           ;
reg [5-1:0] ISR_22           ;
reg [5-1:0] DSR_22           ;
reg [30-1:0] ICD_22           ;
reg [9-1:0] TOL_22           ;


red_pitaya_pid_block #(
  .adc_res (  adc_res_fast  ) 
)
i_pid22
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  dat_b_i        ),  // input data
  .dat_o        (  pid_22_out     ),  // output data

   // settings
  .set_sp_i     (  set_22_sp      ),  // set point
  .set_kp_i     (  set_22_kp      ),  // Kp
  .set_ki_i     (  set_22_ki      ),  // Ki
  .set_kd_i     (  set_22_kd      ),  // Kd
  .int_rst_i    (  set_22_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[3]  ),
        
  // advanced parameters
  .PSR     (  PSR_22      ),  
  .ISR     (  ISR_22      ),
  .DSR     (  DSR_22      ),  
  .ICD     (  ICD_22      ),
  .TOL     (  TOL_22      )   
);



//---------------------------------------------------------------------------------
//  PID SLOW AA
//---------------------------------------------------------------------------------

wire [ 12-1: 0] pid_aa_out   ;	
reg  [ 12-1: 0] set_aa_sp    ;
reg  [ 12-1: 0] set_aa_kp    ;
reg  [ 12-1: 0] set_aa_ki    ;
reg  [ 12-1: 0] set_aa_kd    ;
reg             set_aa_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_aa           ;
reg [5-1:0] ISR_aa           ;
reg [5-1:0] DSR_aa           ;
reg [30-1:0] ICD_aa           ;
reg [9-1:0] TOL_aa           ;

red_pitaya_pid_block #(
  .adc_res (  adc_res_slow  )       
)
i_pidAA
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  adc_slx_a_i    ),  // input data
  .dat_o        (  pid_aa_out     ),  // output data

   // settings
  .set_sp_i     (  set_aa_sp      ),  // set point
  .set_kp_i     (  set_aa_kp      ),  // Kp
  .set_ki_i     (  set_aa_ki      ),  // Ki
  .set_kd_i     (  set_aa_kd      ),  // Kd
  .int_rst_i    (  set_aa_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[4]  ),
      
        // advanced parameters
  .PSR     (  PSR_aa      ),  
  .ISR     (  ISR_aa      ),
  .DSR     (  DSR_aa      ),  
  .ICD     (  ICD_aa      ),
  .TOL     (  TOL_aa      )
);

//---------------------------------------------------------------------------------
//  PID SLOW BB
//---------------------------------------------------------------------------------


wire [ 12-1: 0] pid_bb_out   ;	
reg  [ 12-1: 0] set_bb_sp    ;
reg  [ 12-1: 0] set_bb_kp    ;
reg  [ 12-1: 0] set_bb_ki    ;
reg  [ 12-1: 0] set_bb_kd    ;
reg             set_bb_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_bb           ;
reg [5-1:0] ISR_bb           ;
reg [5-1:0] DSR_bb           ;
reg [30-1:0] ICD_bb           ;
reg [9-1:0] TOL_bb           ;


red_pitaya_pid_block #(
  .adc_res (  adc_res_slow  )      
)
i_pidBB
( 
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  adc_slx_b_i    ),  // input data
  .dat_o        (  pid_bb_out     ),  // output data

   // settings
  .set_sp_i     (  set_bb_sp      ),  // set point
  .set_kp_i     (  set_bb_kp      ),  // Kp
  .set_ki_i     (  set_bb_ki      ),  // Ki
  .set_kd_i     (  set_bb_kd      ),  // Kd
  .int_rst_i    (  set_bb_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[5]  ),
        
  // advanced parameters
  .PSR     (  PSR_bb      ),  
  .ISR     (  ISR_bb      ),
  .DSR     (  DSR_bb      ),  
  .ICD     (  ICD_bb      ),
  .TOL     (  TOL_bb      )
);

//---------------------------------------------------------------------------------
//  PID SLOW CC
//---------------------------------------------------------------------------------


wire [ 12-1: 0] pid_cc_out   ;	
reg  [ 12-1: 0] set_cc_sp    ;
reg  [ 12-1: 0] set_cc_kp    ;
reg  [ 12-1: 0] set_cc_ki    ;
reg  [ 12-1: 0] set_cc_kd    ;
reg             set_cc_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_cc           ;
reg [5-1:0] ISR_cc           ;
reg [5-1:0] DSR_cc           ;
reg [30-1:0] ICD_cc           ;
reg [9-1:0] TOL_cc           ;

red_pitaya_pid_block #(
  .adc_res (  adc_res_slow  )   
)
i_pidCC
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  adc_slx_c_i    ),  // input data
  .dat_o        (  pid_cc_out     ),  // output data

   // settings
  .set_sp_i     (  set_cc_sp      ),  // set point
  .set_kp_i     (  set_cc_kp      ),  // Kp
  .set_ki_i     (  set_cc_ki      ),  // Ki
  .set_kd_i     (  set_cc_kd      ),  // Kd
  .int_rst_i    (  set_cc_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[6]  ),
          
    // advanced parameters
  .PSR     (  PSR_cc      ),  
  .ISR     (  ISR_cc      ),
  .DSR     (  DSR_cc      ),  
  .ICD     (  ICD_cc      ),
  .TOL     (  TOL_cc      )
);

//---------------------------------------------------------------------------------
//  PID SLOW DD
//---------------------------------------------------------------------------------


wire [ 12-1: 0] pid_dd_out   ;	
reg  [ 12-1: 0] set_dd_sp    ;
reg  [ 12-1: 0] set_dd_kp    ;
reg  [ 12-1: 0] set_dd_ki    ;
reg  [ 12-1: 0] set_dd_kd    ;
reg             set_dd_irst  ;

// Advanced Parameters
reg [5-1:0] PSR_dd           ;
reg [5-1:0] ISR_dd           ;
reg [5-1:0] DSR_dd           ;
reg [30-1:0] ICD_dd           ;
reg [9-1:0] TOL_dd          ;

red_pitaya_pid_block #(
  .adc_res (  adc_res_slow  )       
)
i_pidDD
(
   // data
  .clk_i        (  clk_i          ),  // clock
  .rstn_i       (  rstn_i         ),  // reset - active low
  .dat_i        (  adc_slx_d_i    ),  // input data
  .dat_o        (  pid_dd_out     ),  // output data

   // settings
  .set_sp_i     (  set_dd_sp      ),  // set point
  .set_kp_i     (  set_dd_kp      ),  // Kp
  .set_ki_i     (  set_dd_ki      ),  // Ki
  .set_kd_i     (  set_dd_kd      ),  // Kd
  .int_rst_i    (  set_dd_irst    ),   // integrator reset
  .int_hold     (   int_hold_pins[7]  ),
            
      // advanced parameters
  .PSR     (  PSR_dd      ),  
  .ISR     (  ISR_dd      ),
  .DSR     (  DSR_dd      ),  
  .ICD     (  ICD_dd      ),
  .TOL     (  TOL_dd      )
);

//---------------------------------------------------------------------------------
// LED Logic
//---------------------------------------------------------------------------------

reg [8-1:0] leds;

always @(posedge clk_i) begin
    if(rstn_i == 1'b0) begin
        leds <= {8{1'b0}};
     end else begin
        
        if(set_11_sp || set_11_kp || set_11_ki || set_11_kd)       
            leds[0] <= 1'b1;
        else
            leds[0] <= 1'b0;

        if(set_12_sp || set_12_kp || set_12_ki || set_12_kd)          
            leds[1] <= 1'b1;
        else
            leds[1] <= 1'b0;

        if(set_21_sp || set_21_kp || set_21_ki  || set_21_kd)          
            leds[2] <= 1'b1;
        else
            leds[2] <= 1'b0;

        if(set_22_sp  || set_22_kp  || set_22_ki  || set_22_kd )          
            leds[3] <= 1'b1;
        else
            leds[3] <= 1'b0;

        if(set_aa_sp || set_aa_kp || set_aa_ki || set_aa_kd )          
            leds[4] <= 1'b1;
        else
            leds[4] <= 1'b0;
            
        if(set_bb_sp || set_bb_kp || set_bb_ki || set_bb_kd)          
            leds[5] <= 1'b1;
        else
            leds[6] <= 1'b0;            
            
        if(set_cc_sp || set_cc_kp || set_cc_ki || set_cc_kd )          
            leds[6] <= 1'b1;
        else
            leds[6] <= 1'b0;
            
        if(set_dd_sp || set_dd_kp|| set_dd_ki || set_dd_kd)          
            leds[7] <= 1'b1;
        else
            leds[7] <= 1'b0;            
    end
 end
 
 assign led = leds;
    
  
           
//---------------------------------------------------------------------------------
//  Sum and saturation for fast PIDS
//---------------------------------------------------------------------------------


wire [ 15-1: 0] out_1_sum   ;
reg  [ 14-1: 0] out_1_sat   ;
wire [ 15-1: 0] out_2_sum   ;
reg  [ 14-1: 0] out_2_sat   ;

assign out_1_sum = $signed(pid_11_out) + $signed(pid_12_out);
assign out_2_sum = $signed(pid_22_out) + $signed(pid_21_out);

always @(posedge clk_i) begin
   if (rstn_i == 1'b0) begin
      out_1_sat <= 14'd0 ;
      out_2_sat <= 14'd0 ;
   end
   else begin
      if (out_1_sum[15-1:15-2]==2'b01) // postitive sat
         out_1_sat <= 14'h1FFF ;
      else if (out_1_sum[15-1:15-2]==2'b10) // negative sat
         out_1_sat <= 14'h2000 ;
      else
         out_1_sat <= out_1_sum[14-1:0] ;

      if (out_2_sum[15-1:15-2]==2'b01) // postitive sat
         out_2_sat <= 14'h1FFF ;
      else if (out_2_sum[15-1:15-2]==2'b10) // negative sat
         out_2_sat <= 14'h2000 ;
      else
         out_2_sat <= out_2_sum[14-1:0] ;
   end
end


assign dat_a_o = out_1_sat ;
assign dat_b_o = out_2_sat ;


//---------------------------------------------------------------------------------
// Conversion to 24-bit DAC format for for slow PIDs
//---------------------------------------------------------------------------------

wire [24-1: 0] out_a_sat  ;
wire [24-1: 0] out_b_sat  ;
wire [24-1: 0] out_c_sat  ;
wire [24-1: 0] out_d_sat  ;

slow_dac_converter s_dac_a
(
    .clk_i  (   clk_i   ),
    .rstn_i (   rstn_i  ),
    .dat_i  (   pid_aa_out  ),
    .dat_o  (   out_a_sat   )
);

slow_dac_converter s_dac_b
(
    .clk_i  (   clk_i   ),
    .rstn_i (   rstn_i  ),
    .dat_i  (   pid_bb_out  ),
    .dat_o  (   out_b_sat   )
);

slow_dac_converter s_dac_c
(
    .clk_i  (   clk_i   ),
    .rstn_i (   rstn_i  ),
    .dat_i  (   pid_cc_out  ),
    .dat_o  (   out_c_sat   )
);

slow_dac_converter s_dac_d
(
    .clk_i  (   clk_i   ),
    .rstn_i (   rstn_i  ),
    .dat_i  (   pid_dd_out  ),
    .dat_o  (   out_d_sat   )
);

assign dac_pwm_a_o = out_a_sat ;
assign dac_pwm_b_o = out_b_sat ;
assign dac_pwm_c_o = out_c_sat ;
assign dac_pwm_d_o = out_d_sat ;

//---------------------------------------------------------------------------------
//  System bus connection
//---------------------------------------------------------------------------------

always @(posedge clk_i) begin
   if (rstn_i == 1'b0) begin
      set_11_sp    <= 14'd0 ;
      set_11_kp    <= 14'd0 ;
      set_11_ki    <= 14'd0 ;
      set_11_kd    <= 14'd0 ;
      set_11_irst  <=  1'b1 ;
      
      set_12_sp    <= 14'd0 ;
      set_12_kp    <= 14'd0 ;
      set_12_ki    <= 14'd0 ;
      set_12_kd    <= 14'd0 ;
      set_12_irst  <=  1'b1 ;
      
      set_21_sp    <= 14'd0 ;
      set_21_kp    <= 14'd0 ;
      set_21_ki    <= 14'd0 ;
      set_21_kd    <= 14'd0 ;
      set_21_irst  <=  1'b1 ;
      
      set_22_sp    <= 14'd0 ;
      set_22_kp    <= 14'd0 ;
      set_22_ki    <= 14'd0 ;
      set_22_kd    <= 14'd0 ;
      set_22_irst  <=  1'b1 ;
      
      set_aa_sp    <= 12'd0 ;
      set_aa_kp    <= 12'd0 ;
      set_aa_ki    <= 12'd0 ;
      set_aa_kd    <= 12'd0 ;
      set_aa_irst  <=  1'b1 ;
      
      set_bb_sp    <= 12'd0 ;
      set_bb_kp    <= 12'd0 ;
      set_bb_ki    <= 12'd0 ;
      set_bb_kd    <= 12'd0 ;
      set_bb_irst  <=  1'b1 ;
      
      set_cc_sp    <= 12'd0 ;
      set_cc_kp    <= 12'd0 ;
      set_cc_ki    <= 12'd0 ;
      set_cc_kd    <= 12'd0 ;
      set_cc_irst  <=  1'b1 ;
      
      set_dd_sp    <= 12'd0 ;
      set_dd_kp    <= 12'd0 ;
      set_dd_ki    <= 12'd0 ;
      set_dd_kd    <= 12'd0 ;
      set_dd_irst  <=  1'b1 ;          
      
      PSR_11       <= 5'd12 ; // set to default fast values
      ISR_11       <= 5'd18 ;      
      DSR_11       <= 5'd10 ;     
      ICD_11       <= 30'd0  ;      
      TOL_11       <= 9'd0;
      
      PSR_12       <= 5'd12 ; 
      ISR_12       <= 5'd18 ;      
      DSR_12       <= 5'd10 ;     
      ICD_12       <= 30'd0  ;      
      TOL_12       <= 9'd0;
            
      PSR_21       <= 5'd12 ; 
      ISR_21       <= 5'd18 ;      
      DSR_21       <= 5'd10 ;     
      ICD_21       <= 30'd0  ;       
      TOL_21       <= 9'd0;
            
      PSR_22       <= 5'd12 ; 
      ISR_22       <= 5'd18 ;      
      DSR_22       <= 5'd10 ;     
      ICD_22       <= 30'd0  ;       
      TOL_22       <= 9'd0;
            
      PSR_aa       <= 5'd8 ; // set to default slow values
      ISR_aa       <= 5'd20 ;      
      DSR_aa       <= 5'd6 ;     
      ICD_aa       <= 30'd0  ;       
      TOL_aa       <= 9'd0;
      
      PSR_bb       <= 5'd8 ; 
      ISR_bb       <= 5'd20 ;      
      DSR_bb       <= 5'd6 ;     
      ICD_bb       <= 30'd0  ;        
      TOL_bb       <= 9'd0;
 
      PSR_cc       <= 5'd8 ; 
      ISR_cc       <= 5'd20 ;      
      DSR_cc       <= 5'd6 ;     
      ICD_cc       <= 30'd0  ;  
      TOL_cc       <= 9'd0;
      
      PSR_dd       <= 5'd8 ; 
      ISR_dd       <= 5'd20 ;      
      DSR_dd       <= 5'd6 ;     
      ICD_dd       <= 30'd0  ;   
      TOL_dd       <= 9'd0;
            
   end
   else begin
      if (wen) begin
       
         if (addr[19:0]==16'h90)    set_11_irst  <= wdata[1-1: 0] ; //just a 1 bit number
         if (addr[19:0]==16'h10)    set_11_sp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h14)    set_11_kp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h18)    set_11_ki  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h1C)    set_11_kd  <= wdata[14-1:0] ;
         
         if (addr[19:0]==16'h94)    set_12_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h20)    set_12_sp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h24)    set_12_kp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h28)    set_12_ki  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h2C)    set_12_kd  <= wdata[14-1:0] ;
         
         if (addr[19:0]==16'h98)    set_21_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h30)    set_21_sp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h34)    set_21_kp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h38)    set_21_ki  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h3C)    set_21_kd  <= wdata[14-1:0] ;
         
         if (addr[19:0]==16'h9C)    set_22_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h40)    set_22_sp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h44)    set_22_kp  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h48)    set_22_ki  <= wdata[14-1:0] ;
         if (addr[19:0]==16'h4C)    set_22_kd  <= wdata[14-1:0] ;
         
         if (addr[19:0]==16'hA0)    set_aa_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h50)    set_aa_sp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h54)    set_aa_kp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h58)    set_aa_ki  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h5C)    set_aa_kd  <= wdata[12-1:0] ;         
 
         if (addr[19:0]==16'hA4)    set_bb_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h60)    set_bb_sp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h64)    set_bb_kp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h68)    set_bb_ki  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h6C)    set_bb_kd  <= wdata[12-1:0] ; 
 
         if (addr[19:0]==16'hA8)    set_cc_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h70)    set_cc_sp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h74)    set_cc_kp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h78)    set_cc_ki  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h7C)    set_cc_kd  <= wdata[12-1:0] ;      
         
         if (addr[19:0]==16'hAC)    set_dd_irst  <= wdata[1-1:0] ;
         if (addr[19:0]==16'h80)    set_dd_sp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h84)    set_dd_kp  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h88)    set_dd_ki  <= wdata[12-1:0] ;
         if (addr[19:0]==16'h8C)    set_dd_kd  <= wdata[12-1:0] ;            
         
         if (addr[19:0]==16'hB0)    PSR_11  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hB4)    ISR_11  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hB8)    DSR_11  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hBC)    ICD_11  <= wdata[30-1:0] ;         
         if (addr[19:0]==16'h130)   TOL_11  <= wdata[9-1:0] ; 
         
         if (addr[19:0]==16'hC0)    PSR_12  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hC4)    ISR_12  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hC8)    DSR_12  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hCC)    ICD_12  <= wdata[30-1:0] ;          
        if (addr[19:0]==16'h134)    TOL_12  <= wdata[9-1:0] ;
                  
         if (addr[19:0]==16'hD0)    PSR_21  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hD4)    ISR_21  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hD8)    DSR_21  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hDC)    ICD_21  <= wdata[30-1:0] ;           
        if (addr[19:0]==16'h138)    TOL_21  <= wdata[9-1:0] ;
                 
         if (addr[19:0]==16'hE0)    PSR_22  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hE4)    ISR_22  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hE8)    DSR_22  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hEC)    ICD_22  <= wdata[30-1:0] ;           
         if (addr[19:0]==16'h13C)    TOL_22  <= wdata[9-1:0] ;
                 
         if (addr[19:0]==16'hF0)    PSR_aa  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hF4)    ISR_aa  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hF8)    DSR_aa  <= wdata[5-1:0] ;
         if (addr[19:0]==16'hFC)    ICD_aa  <= wdata[30-1:0] ;          
         if (addr[19:0]==16'h140)    TOL_aa  <= wdata[9-1:0] ;
                  
         if (addr[19:0]==16'h100)    PSR_bb  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h104)    ISR_bb  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h108)    DSR_bb  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h10C)    ICD_bb  <= wdata[30-1:0] ;         
         if (addr[19:0]==16'h144)    TOL_bb  <= wdata[9-1:0] ;
                  
         if (addr[19:0]==16'h110)    PSR_cc  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h114)    ISR_cc  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h118)    DSR_cc  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h11C)    ICD_cc  <= wdata[30-1:0] ;          
          if (addr[19:0]==16'h148)   TOL_cc  <= wdata[9-1:0] ;
                  
         if (addr[19:0]==16'h120)    PSR_dd  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h124)    ISR_dd  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h128)    DSR_dd  <= wdata[5-1:0] ;
         if (addr[19:0]==16'h12C)    ICD_dd  <= wdata[30-1:0] ;         
         if (addr[19:0]==16'h14C)    TOL_dd  <= wdata[9-1:0] ;
                              
      end
   end
end


always @(*) begin
   err <= 1'b0 ;

   casez (addr[19:0])

      20'h90 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_11_irst}         ; end     
      20'h10 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_11_sp}          ; end 
      20'h14 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_11_kp}          ; end 
      20'h18 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_11_ki}          ; end 
      20'h1C : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_11_kd}          ; end 

      20'h94 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_12_irst}         ; end     
      20'h20 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_12_sp}          ; end 
      20'h24 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_12_kp}          ; end 
      20'h28 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_12_ki}          ; end 
      20'h2C : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_12_kd}          ; end 

      20'h98 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_21_irst}         ; end     
      20'h30 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_21_sp}          ; end 
      20'h34 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_21_kp}          ; end 
      20'h38 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_21_ki}          ; end 
      20'h3C : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_21_kd}          ; end 

      20'h9C : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_22_irst}         ; end     
      20'h40 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_22_sp}          ; end 
      20'h44 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_22_kp}          ; end 
      20'h48 : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_22_ki}          ; end 
      20'h4C : begin ack <= 1'b1;          rdata <= {{32-14{1'b0}}, set_22_kd}          ; end 

      20'hA0 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_aa_irst}         ; end     
      20'h50 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_aa_sp}          ; end 
      20'h54 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_aa_kp}          ; end 
      20'h58 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_aa_ki}          ; end 
      20'h5C : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_aa_kd}          ; end 

      20'hA4 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_bb_irst}         ; end     
      20'h60 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_bb_sp}          ; end 
      20'h64 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_bb_kp}          ; end 
      20'h68 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_bb_ki}          ; end 
      20'h6C : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_bb_kd}          ; end 

      20'hA8 : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_cc_irst}         ; end     
      20'h70 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_cc_sp}          ; end 
      20'h74 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_cc_kp}          ; end 
      20'h78 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_cc_ki}          ; end 
      20'h7C : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_cc_kd}          ; end 

      20'hAC : begin ack <= 1'b1;          rdata <= {{32-1{1'b0}}, set_dd_irst}         ; end     
      20'h80 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_dd_sp}          ; end 
      20'h84 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_dd_kp}          ; end 
      20'h88 : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_dd_ki}          ; end 
      20'h8C : begin ack <= 1'b1;          rdata <= {{32-12{1'b0}}, set_dd_kd}          ; end 
      
      20'hB0 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_11}             ; end     
      20'hB4 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_11}             ; end 
      20'hB8 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_11}             ; end 
      20'hBC : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_11}             ; end 
      20'h130 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_11}             ; end 
         
      20'hC0 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_12}             ; end     
      20'hC4 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_12}             ; end 
      20'hC8 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_12}             ; end 
      20'hCC : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_12}             ; end       
      20'h134 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_12}             ; end 
            
      20'hD0 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_21}             ; end     
      20'hD4 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_21}             ; end 
      20'hD8 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_21}             ; end 
      20'hDC : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_21}             ; end       
      20'h138 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_21}             ; end 
            
      20'hE0 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_22}             ; end     
      20'hE4 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_22}             ; end 
      20'hE8 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_22}             ; end 
      20'hEC : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_22}             ; end       
      20'h13C : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_22}             ; end
            
      20'hF0 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_aa}             ; end     
      20'hF4 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_aa}             ; end 
      20'hF8 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_aa}             ; end 
      20'hFC : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_aa}             ; end      
      20'h140 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_aa}             ; end
            
      20'h100 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_bb}             ; end     
      20'h104 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_bb}             ; end 
      20'h108 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_bb}             ; end 
      20'h10C : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_bb}             ; end       
      20'h144 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_bb}             ; end
            
      20'h110 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_cc}             ; end     
      20'h114 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_cc}             ; end 
      20'h118 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_cc}             ; end 
      20'h11C : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_cc}             ; end       
      20'h148 : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_cc}             ; end
            
      20'h120 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, PSR_dd}             ; end     
      20'h124 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, ISR_dd}             ; end 
      20'h128 : begin ack <= 1'b1;          rdata <= {{32-5{1'b0}}, DSR_dd}             ; end 
      20'h12C : begin ack <= 1'b1;          rdata <= {{32-30{1'b0}}, ICD_dd}             ; end       
      20'h14C : begin ack <= 1'b1;          rdata <= {{32-9{1'b0}}, TOL_dd}             ; end     
     default : begin ack <= 1'b1;          rdata <=  32'h0                              ; end
   endcase
end


// bridge between processing and sys clock
bus_clk_bridge i_bridge
(
   .sys_clk_i     (  sys_clk_i      ),
   .sys_rstn_i    (  sys_rstn_i     ),
   .sys_addr_i    (  sys_addr_i     ),
   .sys_wdata_i   (  sys_wdata_i    ),
   .sys_sel_i     (  sys_sel_i      ),
   .sys_wen_i     (  sys_wen_i      ),
   .sys_ren_i     (  sys_ren_i      ),
   .sys_rdata_o   (  sys_rdata_o    ),
   .sys_err_o     (  sys_err_o      ),
   .sys_ack_o     (  sys_ack_o      ),

   .clk_i         (  clk_i          ),
   .rstn_i        (  rstn_i         ),
   .addr_o        (  addr           ),
   .wdata_o       (  wdata          ),
   .wen_o         (  wen            ),
   .ren_o         (  ren            ),
   .rdata_i       (  rdata          ),
   .err_i         (  err            ),
   .ack_i         (  ack            )
);






endmodule
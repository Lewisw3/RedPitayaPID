/**
 * $Id: red_pitaya_ams.v 961 2014-01-21 11:40:39Z matej.oblak $
 *
 * @brief Red Pitaya analog mixed signal.
 *
 * @Author Matej Oblak
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */



/**
 * GENERAL DESCRIPTION:
 *
 * Module using XADC and software interface for PWM DAC.
 *
 *
 *                    /------\
 *   SUPPLY V. -----> |      |
 *   TEMPERATURE ---> | XADC | ------
 *   EXTERNAL V. ---> |      |       |
 *                    \------/       |
 *                                   |
 *                                   ˇ
 *                               /------\
 *   PWD DAC <------------------ | REGS | <------> SW
 *                               \------/
 *
 *
 * Reading system and external voltages is done with XADC, running in sequencer
 * mode. It measures supply voltages, temperature and voltages on external
 * connector. Measured values are then exposed to SW.
 *
 * Beside that SW can sets registes which controls logic for PWM DAC (analog module).
 * 
 */





module red_pitaya_ams
(
   // ADC
   input                 clk_i           ,  //!< clock
   input                 rstn_i          ,  //!< reset - active low
   input      [  5-1: 0] vinp_i          ,  //!< voltages p
   input      [  5-1: 0] vinn_i          ,  //!< voltages n

   // PWM DAC
   output     [ 24-1: 0] dac_a_o         ,  //!< values used for
   output     [ 24-1: 0] dac_b_o         ,  //!< conversion into PWM signal
   output     [ 24-1: 0] dac_c_o         ,  //!< 
   output     [ 24-1: 0] dac_d_o         ,  //!< 

   input   [ 12-1: 0] adc_temp_r   ,
   input   [ 12-1: 0] adc_pint_r   ,
   input   [ 12-1: 0] adc_paux_r   ,
   input   [ 12-1: 0] adc_bram_r   ,
   input   [ 12-1: 0] adc_int_r    ,
   input   [ 12-1: 0] adc_aux_r    ,
   input   [ 12-1: 0] adc_ddr_r    ,

   input   [ 12-1: 0] adc_a_r      ,
   input   [ 12-1: 0] adc_b_r      ,
   input   [ 12-1: 0] adc_c_r      ,
   input   [ 12-1: 0] adc_d_r      ,
   input   [ 12-1: 0] adc_v_r      ,

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





//---------------------------------------------------------------------------------
//
//  System bus connection

wire  [ 32-1: 0] addr         ;
wire  [ 32-1: 0] wdata        ;
wire             wen          ;
wire             ren          ;
reg   [ 32-1: 0] rdata        ;
reg              err          ;
reg              ack          ;

reg   [ 24-1: 0] dac_a_r      ;
reg   [ 24-1: 0] dac_b_r      ;
reg   [ 24-1: 0] dac_c_r      ;
reg   [ 24-1: 0] dac_d_r      ;

always @(posedge clk_i) begin
   if (rstn_i == 1'b0) begin
      dac_a_r     <= 24'd0 ;
      dac_b_r     <= 24'd0 ;
      dac_c_r     <= 24'd0 ;
      dac_d_r     <= 24'd0 ;
   end
   else begin
      if (wen) begin
         if (addr[19:0]==16'h20)   dac_a_r <= wdata[24-1: 0] ;
         if (addr[19:0]==16'h24)   dac_b_r <= wdata[24-1: 0] ;
         if (addr[19:0]==16'h28)   dac_c_r <= wdata[24-1: 0] ;
         if (addr[19:0]==16'h2C)   dac_d_r <= wdata[24-1: 0] ;
      end
   end
end

always @(posedge clk_i) begin
   err <= 1'b0 ;

   casez (addr[19:0])
     20'h00000 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_a_r}          ; end
     20'h00004 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_b_r}          ; end
     20'h00008 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_c_r}          ; end
     20'h0000C : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_d_r}          ; end
     20'h00010 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_v_r}          ; end

     20'h00020 : begin ack <= 1'b1;         rdata <= {{32-24{1'b0}}, dac_a_r}          ; end
     20'h00024 : begin ack <= 1'b1;         rdata <= {{32-24{1'b0}}, dac_b_r}          ; end
     20'h00028 : begin ack <= 1'b1;         rdata <= {{32-24{1'b0}}, dac_c_r}          ; end
     20'h0002C : begin ack <= 1'b1;         rdata <= {{32-24{1'b0}}, dac_d_r}          ; end

     20'h00030 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_temp_r}       ; end
     20'h00034 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_pint_r}       ; end
     20'h00038 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_paux_r}       ; end
     20'h0003C : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_bram_r}       ; end
     20'h00040 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_int_r}        ; end
     20'h00044 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_aux_r}        ; end
     20'h00048 : begin ack <= 1'b1;         rdata <= {{32-12{1'b0}}, adc_ddr_r}        ; end

       default : begin ack <= 1'b1;         rdata <=   32'h0                           ; end
   endcase
end



assign dac_a_o = dac_a_r ;
assign dac_b_o = dac_b_r ;
assign dac_c_o = dac_c_r ;
assign dac_d_o = dac_d_r ;


// bridge between ADC and sys clock
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

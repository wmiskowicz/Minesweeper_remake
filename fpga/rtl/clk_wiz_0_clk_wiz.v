
// file: clk_wiz_1.v
// 
// (c) Copyright 2008 - 2013 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk100MHz__100.00000______0.000______50.0______122.532_____91.877
// clk74MHz__74.16667______0.000______50.0______130.215_____91.877
// clk40MHz__39.73214______0.000______50.0______148.685_____91.877
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________100.000____________0.010

`timescale 1ps/1ps

module clk_wiz_1_clk_wiz 

 (// Clock in ports
  // Clock out ports
  output        clk100MHz,
  output        clk74MHz,
  output        clk40MHz,
  // Status and control signals
  input         reset,
  output        locked,
  input         clk
 );
  // Input buffering
  //------------------------------------
wire clk_clk_wiz_1;
wire clk_in2_clk_wiz_1;
  IBUF clkin1_ibufg
   (.O (clk_clk_wiz_1),
    .I (clk));




  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk100MHz_clk_wiz_1;
  wire        clk74MHz_clk_wiz_1;
  wire        clk40MHz_clk_wiz_1;
  wire        clk_out4_clk_wiz_1;
  wire        clk_out5_clk_wiz_1;
  wire        clk_out6_clk_wiz_1;
  wire        clk_out7_clk_wiz_1;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_1;
  wire        clkfbout_buf_clk_wiz_1;
  wire        clkfboutb_unused;
    wire clkout0b_unused;
   wire clkout1b_unused;
   wire clkout2b_unused;
   wire clkout3_unused;
   wire clkout3b_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;
  (* KEEP = "TRUE" *) 
  (* ASYNC_REG = "TRUE" *)
  reg  [7 :0] seq_reg1 = 0;
  (* KEEP = "TRUE" *) 
  (* ASYNC_REG = "TRUE" *)
  reg  [7 :0] seq_reg2 = 0;
  (* KEEP = "TRUE" *) 
  (* ASYNC_REG = "TRUE" *)
  reg  [7 :0] seq_reg3 = 0;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      (0),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         (0),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (11.125),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS (0),
    .CLKOUT0_DIVIDE_F     (11.125),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  (0),
    .CLKOUT1_DIVIDE       (15),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  (0),
    .CLKOUT2_DIVIDE       (28),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  (0),
    .CLKIN1_PERIOD        (10.000))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_1),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clk100MHz_clk_wiz_1),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clk74MHz_clk_wiz_1),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clk40MHz_clk_wiz_1),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_1),
    .CLKIN1              (clk_clk_wiz_1),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (reset_high));
  assign reset_high = reset; 

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_clk_wiz_1),
    .I (clkfbout_clk_wiz_1));







  BUFGCE clkout1_buf
   (.O   (clk100MHz),
    .CE  (seq_reg1[7]),
    .I   (clk100MHz_clk_wiz_1));

  BUFH clkout1_buf_en
   (.O   (clk100MHz_clk_wiz_1_en_clk),
    .I   (clk100MHz_clk_wiz_1));
  always @(posedge clk100MHz_clk_wiz_1_en_clk or posedge reset_high) begin
    if(reset_high == 1'b1) begin
	    seq_reg1 <= 8'h00;
    end
    else begin
        seq_reg1 <= {seq_reg1[6:0],locked_int};
  
    end
  end


  BUFGCE clkout2_buf
   (.O   (clk74MHz),
    .CE  (seq_reg2[7]),
    .I   (clk74MHz_clk_wiz_1));
 
  BUFH clkout2_buf_en
   (.O   (clk74MHz_clk_wiz_1_en_clk),
    .I   (clk74MHz_clk_wiz_1));
 
  always @(posedge clk74MHz_clk_wiz_1_en_clk or posedge reset_high) begin
    if(reset_high == 1'b1) begin
	  seq_reg2 <= 8'h00;
    end
    else begin
        seq_reg2 <= {seq_reg2[6:0],locked_int};
  
    end
  end


  BUFGCE clkout3_buf
   (.O   (clk40MHz),
    .CE  (seq_reg3[7]),
    .I   (clk40MHz_clk_wiz_1));
 
  BUFH clkout3_buf_en
   (.O   (clk40MHz_clk_wiz_1_en_clk),
    .I   (clk40MHz_clk_wiz_1));
 
  always @(posedge clk40MHz_clk_wiz_1_en_clk or posedge reset_high) begin
    if(reset_high == 1'b1) begin
	  seq_reg3 <= 8'h00;
    end
    else begin
        seq_reg3 <= {seq_reg3[6:0],locked_int};
  
    end
  end





endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Color package
 Author:        Wojciech Miskowicz
 Description:   Contains color codes used in RGB display.
 */
//////////////////////////////////////////////////////////////////////////////

package color_pkg;
  
  // Bacground colors
  localparam [11:0] BACKGROUND = 12'hF_D_9;
  localparam [11:0] BACKGROUND_SQUARE = 12'hE_B_6;

  localparam [11:0] BLUE_SCREEN = 12'h0_0_f;

  
  localparam [11:0] RED = 12'hf_0_0;
  localparam [11:0] BLACK = 12'h1_1_1;

  // Button colors
  localparam [11:0] BUTTON_BACK = 12'hd_d_d;
  localparam [11:0] BUTTON_WHITE = 12'hf_f_f;
  localparam [11:0] BUTTON_GRAY = 12'h5_5_5;

  // Number colors
  localparam [11:0] NUM_1 = 12'h1_1_b;
  localparam [11:0] NUM_2 = 12'h0_a_6;
  localparam [11:0] NUM_3 = 12'he_1_1;
  localparam [11:0] NUM_4 = 12'h6_2_3;
  localparam [11:0] NUM_5 = 12'h0_2_3;
  localparam [11:0] NUM_6 = 12'h9_9_9;
  localparam [11:0] NUM_7 = 12'ha_5_1;
  localparam [11:0] NUM_DEFAULT = 12'h0;

endpackage

/**
 * Author: Wojciech Miskowicz
 * 
 * Description:
 * Package with vga related constants. When changing the resolution update the upper
 * section of this file with constants in the standard documentation.
 * For more see:
 * https://ez.analog.com/cfs-file/__key/communityserver-discussions-components-files/331/vesa_5F00_dmt_5F00_1.12.pdf
 */

package vga_pkg;

// Parameters for VGA Display 1280 x 720 @ 60fps using a 74.25 MHz clock;
// Update this section for changing display resolution.

localparam HOR_PIXELS = 1280;
localparam VER_PIXELS = 720;

localparam HOR_TOTAL_TIME = 1650;
localparam VER_TOTAL_TIME = 750;

localparam HOR_BLANK_START = 1280;
localparam HOR_BLANK_TIME  = 370;

localparam HOR_SYNC_START = 1390;
localparam HOR_SYNC_TIME  = 40;

localparam VER_BLANK_START = 720;
localparam VER_BLANK_TIME  = 30;

localparam VER_SYNC_START = 725;
localparam VER_SYNC_TIME  = 5;
  

// Board geometry
localparam X_CENTER = HOR_PIXELS / 2;
localparam Y_CENTER = VER_PIXELS / 2;

// ============================================================
// Internal calcuations

localparam HCOUNT_MAX = HOR_TOTAL_TIME - 1;
localparam VCOUNT_MAX = VER_TOTAL_TIME - 1;

localparam HBLNK_START_FRONT = HOR_BLANK_START - 1;
localparam HBLNK_STOP_FRONT  = HBLNK_START_FRONT + HOR_BLANK_TIME -1;

localparam HSYNC_START = HOR_SYNC_START - 1;
localparam HSYNC_STOP  = HSYNC_START + HOR_SYNC_TIME - 1;

localparam VBLNK_START_FRONT = VER_BLANK_START - 1;
localparam VBLNK_STOP_FRONT  = VBLNK_START_FRONT + VER_BLANK_TIME - 1;

localparam VSYNC_START = VER_SYNC_START - 1;
localparam VSYNC_STOP  = VSYNC_START + VER_SYNC_TIME - 1;

endpackage

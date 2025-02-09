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

// Parameters for VGA Display 1440 x 900 @ 60fps using a 88.75 MHz clock;
// Update this section for changing display resolution.

localparam HOR_PIXELS = 1440;
localparam VER_PIXELS = 900;

localparam HOR_TOTAL_TIME = 1600;
localparam VER_TOTAL_TIME = 926;

localparam HOR_BLANK_START = 1440;
localparam HOR_BLANK_TIME  = 160;

localparam HOR_SYNC_START = 1488;
localparam HOR_SYNC_TIME  = 32;

localparam VER_BLANK_START = 900;
localparam VER_BLANK_TIME  = 26;

localparam VER_SYNC_START = 903;
localparam VER_SYNC_TIME  = 32;

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

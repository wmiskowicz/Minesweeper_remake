/* Author: Wojciech Miskowicz
 * 
 * Description:
 * Package with vga related constants based on 
 * VESA and Industry Standards and Guidelines for Computer Display Monitor Timing (DMT)
 */

package vga_pkg;

    // Parameters for VGA Display 1440 x 900 @ 60fps using a 88.75 MHz clock;
    // For changing display resolition edit this part.

    localparam int H_ACTIVE       = 1440;
    localparam int V_ACTIVE       = 900;
  
    localparam int H_FRONT_PORCH  = 48;
    localparam int H_SYNC_WIDTH   = 32;
    localparam int H_BACK_PORCH   = 80;
  
    localparam int V_FRONT_PORCH  = 3;
    localparam int V_SYNC_WIDTH   = 6;
    localparam int V_BACK_PORCH   = 17;

    // ===============================================================
    // ===============================================================
    // ===============================================================
  
    localparam int H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
    localparam int V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;
  
    localparam int HCOUNT_MAX = H_TOTAL;
    localparam int VCOUNT_MAX = V_TOTAL;
  
    localparam int HSYNC_START = H_ACTIVE + H_FRONT_PORCH;
    localparam int HSYNC_STOP  = HSYNC_START + H_SYNC_WIDTH - 1;
  
    localparam int VSYNC_START = V_ACTIVE + V_FRONT_PORCH;
    localparam int VSYNC_STOP  = VSYNC_START + V_SYNC_WIDTH - 1;
  
    localparam int HBLNK_START = H_ACTIVE; 
    localparam int HBLNK_STOP  = H_TOTAL - 1;
  
    localparam int VBLNK_START = V_ACTIVE;
    localparam int VBLNK_STOP  = V_TOTAL - 1;
  
  endpackage
  

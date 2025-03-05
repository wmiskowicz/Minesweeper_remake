/**
 * Copyright (C) 2023  AGH University of Science and Technology
 * MTM UEC2 Projekt
 * Author: Piotr Kaczmarczyk
 * Modified: Wojciech Miskowicz
 Coding style: safe with FPGA sync reset
 * Description:
 * Draws background.
 */


`timescale 1 ns / 1 ps

module draw_bg (
    input  logic clk,
    input  logic rst,
    vga_if.in in,
    vga_if.out out
);

import vga_pkg::*;


/**
 * Local variables and signals
 */

 logic signed [10:0] x_c = 220;
 logic signed [10:0] y_c = 240;  

 logic [3:0] circle_wave;
 logic [16:0] dist_sq;
 logic signed [10:0] dx_sq, dy_sq;
 

 always_ff @(posedge clk) begin
  dx_sq   <= in.hcount - x_c;
  dy_sq   <= in.vcount - y_c; 
  dist_sq <= dx_sq + dy_sq;  
end

 




/**
 * Internal logic
 */

 always_ff @(posedge clk) begin : background_ff_blk
  if (rst) begin
    out.vcount  <= '0;
    out.vsync   <= '0;
    out.vblnk   <= '0;
    out.hcount  <= '0;
    out.hsync   <= '0;
    out.hblnk   <= '0;
    out.rgb     <= '0;
    circle_wave <= '0;
  end 
  else begin
    out.vcount <= in.vcount;
    out.vsync  <= in.vsync;
    out.vblnk  <= in.vblnk;
    out.hcount <= in.hcount;
    out.hsync  <= in.hsync;
    out.hblnk  <= in.hblnk;
    if (in.vblnk || in.hblnk) begin             
      out.rgb <= in.rgb; // equals to 0, line to avoid warnings                    
    end 
    else begin                              
    circle_wave <= (dist_sq[16:13]); 

    out.rgb[11:8] <= 4'h7 + (circle_wave >> 2);
    out.rgb[7:4]  <= 4'h9 + (circle_wave >> 2);
    out.rgb[3:0]  <= 4'hA + (circle_wave >> 3);
    end
  end
end


endmodule

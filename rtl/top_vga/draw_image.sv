`timescale 1 ns / 1 ps

module draw_image #(
  parameter RECT_WIDTH   = 64,
  parameter RECT_HEIGHT  = 64,
  parameter PATH         = "../../rtl/top_vga/data/bomb.data"
)(
  input  logic clk,
  input  logic rst,
  input  logic [11:0] rect_x_pos,
  input  logic [11:0] rect_y_pos,
  vga_if.in in,
  vga_if.out out
);

import vga_pkg::*;

vga_if delay1_if();
vga_if delay2_if();
vga_if delay3_if();
vga_if delay4_if();



logic [11:0] addr_x;
logic [11:0] addr_y;

logic [11:0] address;
logic [11:0] rgb;

logic blnk = delay3_if.hblnk || delay3_if.vblnk;

assign addr_x = delay2_if.hcount - rect_x_pos;
assign addr_y = delay2_if.vcount - rect_y_pos;


delay_vga u_delay1(
  .clk(clk),
  .rst(rst),
  .in(in),
  .out(delay1_if.out)   
 );

 delay_vga u_delay2(
  .clk(clk),
  .rst(rst),
  .in(delay1_if.in),
  .out(delay2_if.out)   
 );

 delay_vga u_delay3(
  .clk(clk),
  .rst(rst),
  .in(delay2_if.in),
  .out(delay3_if.out)   
 );

 delay_vga u_delay4(
  .clk(clk),
  .rst(rst),
  .in(delay3_if.in),
  .out(delay4_if.out)   
 );

 image_rom #(
   .PATH    (PATH),
   .MEM_SIZE(RECT_HEIGHT * RECT_WIDTH)
 )
 u_image_rom (
   .address(address), //address = {addry[5:0], addrx[5:0]}
   .clk    (clk),
   .rgb    (rgb)
 );



always_ff @(posedge clk) begin : rect_blk
    if (rst) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
        address    <= '0;
    end else begin
        out.vcount <= delay3_if.vcount;
        out.vsync  <= delay3_if.vsync;
        out.vblnk  <= delay3_if.vblnk;
        out.hcount <= delay3_if.hcount;
        out.hsync  <= delay3_if.hsync;
        out.hblnk  <= delay3_if.hblnk;
        address    <= {addr_y[5:0], addr_x[5:0]};
        if(blnk) begin
          out.rgb <= 12'h0_0_0;
        end
        else if ((delay4_if.hcount >= rect_x_pos) && (delay4_if.hcount < rect_x_pos+RECT_WIDTH) && (delay4_if.vcount >= rect_y_pos) && (delay4_if.vcount<(rect_y_pos+RECT_HEIGHT))) begin
           out.rgb <= rgb;
        end
        else begin                                   
           out.rgb <= delay3_if.rgb;  
        end
    end
end

endmodule

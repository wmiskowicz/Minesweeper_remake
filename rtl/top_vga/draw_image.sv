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

  vga_if delayed_if();

  logic [11:0] rel_x, rel_y;
  logic in_image_region;
  
  logic [11:0] address;
  logic [11:0] rom_rgb;

  delay_vga u_delay(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(delayed_if.out)   
  );

  image_rom #(
    .PATH    (PATH),
    .MEM_SIZE(RECT_HEIGHT * RECT_WIDTH)
  ) u_image_rom (
    .address(address),
    .clk    (clk),
    .rgb    (rom_rgb)
  );

  always_comb begin
    rel_x = in.hcount - rect_x_pos;
    rel_y = in.vcount - rect_y_pos;
    in_image_region = (in.hcount >= rect_x_pos) && 
                     (in.hcount < rect_x_pos + RECT_WIDTH) &&
                     (in.vcount >= rect_y_pos) && 
                     (in.vcount < rect_y_pos + RECT_HEIGHT);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      out.vcount  <= '0;
      out.vsync   <= '0;
      out.vblnk   <= '0;
      out.hcount  <= '0;
      out.hsync   <= '0;
      out.hblnk   <= '0;
      out.rgb     <= '0;
      address     <= '0;
    end else begin
      out.vcount <= delayed_if.vcount;
      out.vsync  <= delayed_if.vsync;
      out.vblnk  <= delayed_if.vblnk;
      out.hcount <= delayed_if.hcount;
      out.hsync  <= delayed_if.hsync;
      out.hblnk  <= delayed_if.hblnk;
      address    <= {rel_y[5:0], rel_x[5:0]};

      
      if (delayed_if.hblnk || delayed_if.vblnk)
        out.rgb <= '0;
      else if (in_image_region)
        out.rgb <= rom_rgb;
      else
        out.rgb <= delayed_if.rgb;
    end
  end

endmodule
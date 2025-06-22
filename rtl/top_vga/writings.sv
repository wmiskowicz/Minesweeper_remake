//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Writings
 Author:        Wojciech Miskowicz
 Description:   Module responsible for displaying "Minesweeper" banner and other writings.
 */
//////////////////////////////////////////////////////////////////////////////

 `timescale 1 ns / 1 ps

 module writings (
  input  logic clk,
  input  logic rst,

  input wire [2:0] main_state,
  input wire game_lost,
  input wire game_won,

  vga_if.in  in,
  vga_if.out out

 );

 import vga_pkg::*;
 import game_pkg::*;


// ----- Signal intefaces -----
vga_if banner_vga();
vga_if menu_vga();
vga_if game_over_vga();
vga_if game_won_vga();


// ----- Local variables -----
logic [11:0] rgb_q;

localparam int SIZE = 128;
localparam int SMALL_SIZE = 64;

localparam int PRESCALER = 4;

localparam [11:0] SCALED_SIZE = SIZE * PRESCALER;
localparam [11:0] SMALL_SCALED_SIZE = SMALL_SIZE * PRESCALER;


draw_image #(
  .RECT_WIDTH (SIZE),
  .RECT_HEIGHT(SIZE),
  .PATH       ("../../rtl/top_vga/data/banner_128.data"),
  .PRESCALER  (PRESCALER)
)
u_draw_image1 (
  .clk       (clk),
  .in        (in),
  .out       (banner_vga.out),
  .rect_x_pos(12'(X_CENTER - SCALED_SIZE/2)),
  .rect_y_pos(12'(Y_CENTER - SCALED_SIZE/2)),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (SIZE),
  .RECT_HEIGHT(SIZE),
  .PATH       ("../../rtl/top_vga/data/menu.data"),
  .PRESCALER  (PRESCALER)
)
u_draw_image2 (
  .clk       (clk),
  .in        (in),
  .out       (menu_vga.out),
  .rect_x_pos(12'(X_CENTER - SCALED_SIZE/2)),
  .rect_y_pos(12'(Y_CENTER - SCALED_SIZE/2)),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (SMALL_SIZE),
  .RECT_HEIGHT(SMALL_SIZE),
  .PATH       ("../../rtl/top_vga/data/game_over.data"),
  .PRESCALER  (PRESCALER)
)
u_draw_image3 (
  .clk       (clk),
  .in        (in),
  .out       (game_over_vga.out),
  .rect_x_pos(12'(X_CENTER - SMALL_SCALED_SIZE/2)),
  .rect_y_pos(12'(Y_CENTER - SMALL_SCALED_SIZE/2)),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (SMALL_SIZE),
  .RECT_HEIGHT(SMALL_SIZE),
  .PATH       ("../../rtl/top_vga/data/game_won.data"),
  .PRESCALER  (PRESCALER)
)
u_draw_image4 (
  .clk       (clk),
  .in        (in),
  .out       (game_won_vga.out),
  .rect_x_pos(12'(X_CENTER - SMALL_SCALED_SIZE/2)),
  .rect_y_pos(12'(Y_CENTER - SMALL_SCALED_SIZE/2)),
  .rst       (rst)
);

always_ff @(posedge clk) begin
  rgb_q <= in.rgb;

  if (main_state == BANNER) begin
    out.rgb <= banner_vga.rgb;
  end 
  else if (main_state == MENU) begin
    out.rgb <= menu_vga.rgb;
  end
  else if (main_state == GAME_OVER) begin

    if (game_lost) 
      out.rgb <= game_over_vga.rgb;
    else if (game_won)
      out.rgb <= game_won_vga.rgb;

  end
  else begin
    out.rgb <= rgb_q;
  end

  out.hcount <= banner_vga.hcount;
  out.vcount <= banner_vga.vcount;
  out.hsync  <= banner_vga.hsync;
  out.vsync  <= banner_vga.vsync;
  out.hblnk  <= banner_vga.hblnk;
  out.vblnk  <= banner_vga.vblnk;
end
  
 endmodule

module draw_char #(
  parameter PRESCALER
)(
  input wire clk,
  input wire rst,

  input logic [11:0] char_code,
  input logic [11:0] char_xpos,
  input logic [11:0] char_ypos,

  input logic [11:0] num_color,

  vga_if.in in,
  vga_if.out out
);

localparam PIXEL_MASK = 8'b1000_0000;


logic [10:0] char_mask;
logic [10:0] char_vcount;
logic [3:0] char_line;

logic [7:0] char_pixels;

assign char_vcount = in.vcount - char_ypos;
assign char_mask = in.hcount - char_xpos;

assign char_line = char_vcount[3:0];


always_ff @(posedge clk) begin
  if (rst) begin
    out.vcount <= '0;
    out.vblnk  <= '0;
    out.vsync  <= '0;
    out.hcount <= '0;
    out.hsync  <= '0;
    out.hblnk  <= '0;
    out.rgb    <= '0;
  end
  else begin
    out.vcount <= in.vcount;
    out.vsync  <= in.vsync;
    out.vblnk  <= in.vblnk;
    out.hcount <= in.hcount;
    out.hsync  <= in.hsync;
    out.hblnk  <= in.hblnk;
    if (char_pixels & (PIXEL_MASK >> char_mask[2:0])) begin
      out.rgb <= num_color;
    end
    else begin                             
      out.rgb <= in.rgb;   
    end   end
end


font_rom #(
  .PRESCALER(PRESCALER)
)u_font_rom (
  .clk             (clk),
  .addr            ({char_code[6:0], char_line[3:0]}),
  .char_line_pixels(char_pixels)
);
  
endmodule

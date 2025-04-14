module draw_char #(
  parameter PRESCALER = 1,
  parameter OFFSET_X = 0
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

localparam bit [255:0] PIXEL_MASK = 1 << (PRESCALER * 8);
localparam MASK_LEN = $clog2(8*PRESCALER);


logic [10:0] char_hcount, scale_hcount;
logic [10:0] char_vcount, scale_vcount;
logic [10:0] vcount_reg;
logic [3:0] char_line;
logic [10:0] hcount_del;

logic [(PRESCALER*8)-1:0] char_pixels;

assign char_line = char_vcount[3:0];

assign char_vcount = scale_vcount - char_ypos;
assign char_hcount = in.hcount - char_xpos;




always_ff @(posedge clk) begin
  if (rst) begin
    scale_vcount <= 11'h0; 
    scale_hcount <= 11'h0; 
    vcount_reg   <= 11'h0;
  end
  else if (PRESCALER != 1) begin
    vcount_reg   <= in.vcount;
    scale_vcount <= (vcount_reg != in.vcount && in.vcount % PRESCALER == 0) ? scale_vcount + 1 : scale_vcount;
    scale_hcount <= (in.hcount % PRESCALER == 0) ? scale_hcount + 1 : scale_hcount;
  end
  else begin
    vcount_reg   <= in.vcount;
    scale_vcount <= in.vcount;
    scale_hcount <= in.hcount;
  end
end


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
    if (char_pixels & (PIXEL_MASK >> char_hcount[MASK_LEN-1:0])) begin
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

delay #(
  .WIDTH  (11),
  .CLK_DEL(OFFSET_X)
)
u_delay (
  .clk (clk), 
  .rst (rst),

  .din (in.vcount), 
  .dout(hcount_del)
);
  
endmodule

//////////////////////////////////////////////////////////////////////////////
/*
  Module name:   level_select
  Author:        Wojciech Miskowicz
  Description:   Module responsible for selecting level based on mouse click.
*/
//////////////////////////////////////////////////////////////////////////////

module level_select (
  input  wire  clk,
  input  wire  rst,

  input logic        left,
  input logic [11:0] mouse_xpos,
  input logic [11:0] mouse_ypos,

  output logic [1:0] level
);

localparam logic [11:0] XPOS_LOW = 12'h204;   
localparam logic [11:0] XPOS_HI =  12'h2F9;  

localparam logic [11:0] YPOS_EZ_LO =  12'h131;   
localparam logic [11:0] YPOS_EZ_HI =  12'h178;   
localparam logic [11:0] YPOS_MD_LO =  12'h193;   
localparam logic [11:0] YPOS_MD_HI =  12'h1DA;     
localparam logic [11:0] YPOS_HD_LO =  12'h1F3;   
localparam logic [11:0] YPOS_HD_HI =  12'h239;   


always_ff @(posedge clk) begin
  if (rst) begin
    level <= 2'h0;
  end
  else if (left && mouse_xpos >= XPOS_LOW && mouse_xpos <= XPOS_HI) begin
    if (mouse_ypos > YPOS_EZ_LO && mouse_ypos < YPOS_EZ_HI)
      level <= 2'd1;
    else if (mouse_ypos > YPOS_MD_LO && mouse_ypos < YPOS_MD_HI)
      level <= 2'd2;
    else if (mouse_ypos > YPOS_HD_LO && mouse_ypos < YPOS_HD_HI)
      level <= 2'd3;
  end
  else
    level <= 2'h0;
end

endmodule

`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Draw board
 Author:        Wojciech Miskowicz
 Description:   Implements module for drawing game board.
 */
//////////////////////////////////////////////////////////////////////////////
module draw_board (
    input  wire  clk,
    input  wire  rst,

    input  logic [2:0] main_state,
    vga_if.in in,
    vga_if.out out
  );

  import color_pkg::*;
  import game_pkg::*;

  //------------------------------------------------------------------------------
  // Local parameters

  localparam STATE_BITS = 3;
  localparam MARGIN = 5;
  localparam SETTINGS_REG_NUM = 9;

  //------------------------------------------------------------------------------
  // local variables

  logic [10:0] board_hcount, board_vcount;
  logic [5:0] field_hcount, field_vcount;
  logic hcount_valid, vcount_valid;

  assign vcount_valid = in.vcount >= M_BOARD_YPOS && in.vcount < M_BOARD_YPOS + M_BOARD_SIZE;
  assign hcount_valid = in.hcount >= M_BOARD_XPOS && in.hcount < M_BOARD_XPOS + M_BOARD_SIZE;

  assign board_vcount = vcount_valid && hcount_valid ? in.vcount - M_BOARD_YPOS : 11'h7_f_f;
  assign board_hcount = vcount_valid && hcount_valid ? in.hcount - M_BOARD_XPOS : 11'h7_f_f;

  assign field_hcount = board_hcount[5:0];
  assign field_vcount = board_vcount[5:0];

  enum logic [STATE_BITS-1 :0] {
    IDLE,
    READ_SETTINGS,
    DRAW
  } state;


  always_ff @(posedge clk) begin
    if(rst)begin
      state <= IDLE;
      out.vcount  <= '0;
      out.vsync   <= '0;
      out.vblnk   <= '0;
      out.hcount  <= '0;
      out.hsync   <= '0;
      out.hblnk   <= '0;
      out.rgb     <= '0;
    end
    else begin
      out.vcount  <= in.vcount;
      out.vsync   <= in.vsync;
      out.vblnk   <= in.vblnk;
      out.hcount  <= in.hcount;
      out.hsync   <= in.hsync;
      out.hblnk   <= in.hblnk;
      case(state)
        IDLE: begin 
          state <= main_state == PLAY ? DRAW : IDLE;
          out.rgb <= in.rgb;
        end
        READ_SETTINGS: begin

        end
        DRAW: begin 
          state <= main_state == GAME_OVER ? IDLE : DRAW;
          out.rgb <= draw_button();
        end
        default: state <= IDLE;
      endcase
    end
  end


  function logic [11:0] draw_button;
    if (field_hcount >= MARGIN && field_hcount <= M_FIELD_SIZE-MARGIN && field_vcount >= MARGIN && field_vcount <= M_FIELD_SIZE-MARGIN &&
    hcount_valid && vcount_valid) begin
      return BUTTON_BACK;
    end
    else if (hcount_valid && vcount_valid) begin
      if(field_hcount >= field_vcount) begin
        return BUTTON_WHITE;
      end
      else begin
        return BUTTON_GRAY;
      end
    end
    return in.rgb;
  endfunction

endmodule
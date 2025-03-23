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
    vga_if.out out,

    wishbone_if.master game_settings_wb,
    wishbone_if.master game_board_wb
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
  logic [15:0] game_setup_cashe [SETTINGS_REG_NUM-1:0];


  logic [10:0] board_hcount, board_vcount;
  logic [5:0] field_hcount, field_vcount;
  logic hcount_valid, vcount_valid;

  logic burst_active;
  logic [15:0] read_data;
  logic [7:0] read_addr;
  logic [3:0] settings_read_ctr;
  logic read_en;
  logic read_ready;

  //------------------------------------------------------------------------------
  // signal assignments

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
  } board_state;




  always_ff @(posedge clk) begin
    if(rst)begin
      board_state <= IDLE;
      out.vcount  <= '0;
      out.vsync   <= '0;
      out.vblnk   <= '0;
      out.hcount  <= '0;
      out.hsync   <= '0;
      out.hblnk   <= '0;
      out.rgb     <= '0;

      burst_active <= 1'b0;
      read_addr    <= 8'b0;
      settings_read_ctr <= 4'b0;
      read_en <= 1'b0;
    end
    else begin
      out.vcount  <= in.vcount;
      out.vsync   <= in.vsync;
      out.vblnk   <= in.vblnk;
      out.hcount  <= in.hcount;
      out.hsync   <= in.hsync;
      out.hblnk   <= in.hblnk;

      case(board_state)
        IDLE: begin 
          burst_active <= 1'b0;
          board_state <= main_state == PLAY ? READ_SETTINGS : IDLE;
          read_en <= main_state == PLAY;
          read_addr <= 8'h0;
          out.rgb <= in.rgb;
        end
        READ_SETTINGS: begin
          burst_active <= 1'b1;
          read_en <= 1'b0;
          board_state <= settings_read_ctr == SETTINGS_REG_NUM ? DRAW : READ_SETTINGS; 

          if (read_ready && settings_read_ctr < SETTINGS_REG_NUM) begin
            game_setup_cashe[settings_read_ctr] <= read_data;
            settings_read_ctr <= settings_read_ctr + 1;
            read_addr <= (settings_read_ctr + 1) * 8'h2;
            read_en <= 1'b1;
          end
        end
        DRAW: begin 
          burst_active <= 1'b0;
          read_en <= 1'b0;
          board_state <= main_state == GAME_OVER ? IDLE : DRAW;
          out.rgb <= draw_button();
        end
        default: board_state <= IDLE;
      endcase
    end
  end

  // Auto read logic
  // TODO

  wishbone_master u_wishbone_master (
    .clk         (clk),
    .rst         (rst),

    .burst_active(burst_active),
    .read_addr   (read_addr),
    .read_data   (read_data),
    .read_en     (read_en),
    .read_ready  (read_ready),

    .wb_master   (game_settings_wb),

    .write_addr  ('0),
    .write_data  ('0),
    .write_en    ('0),
    .write_ready ()
  );

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
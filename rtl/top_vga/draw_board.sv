//////////////////////////////////////////////////////////////////////////////
 /*
  Module name:   Draw board
  Author:        Wojciech Miskowicz
  Description:   Implements module for drawing game board.
  */
//////////////////////////////////////////////////////////////////////////////
`include "../memory/wishbone_defs.svh"
  
module draw_board (
  input  wire  clk,
  input  wire  rst,
  input  wire  retry, 

  input  logic [2:0] main_state,
  vga_if.in in,
  vga_if.out out,

  wishbone_if.master game_settings_wb,
  wishbone_if.master game_board_wb
);

import color_pkg::*;
import game_pkg::*;
import vga_pkg::*;

enum logic [1:0] {
  WAIT,
  AUTO_READ
} auto_read_state;

vga_if bomb_vga();
vga_if flag_vga();
vga_if num_vga();
vga_if stage1_vga();
vga_if stage2_vga();

// ----- Local parameters -----
localparam STATE_BITS = 3;
localparam MARGIN = 5;
localparam SETTINGS_REG_NUM = 9;


// ----- Local variables -----
logic [15:0] game_setup_cashe [SETTINGS_REG_NUM-1:0];
field_t game_board_mem [15:0][15:0];


logic [10:0] board_hcount, board_vcount;
logic [5:0] field_hcount, field_vcount;
logic hcount_valid, vcount_valid;

logic burst_active;
logic [15:0] read_data;
logic [7:0] read_addr;
logic [3:0] settings_read_ctr;
logic read_en;
logic read_ready;

logic game_burst_active;
logic [8:0]  game_read_addr;
logic [15:0] game_read_data;
logic game_read_en;
logic game_read_ready;

logic [3:0] board_ind_x;
logic [3:0] board_ind_y;

logic [11:0] char_code;
logic [11:0] num_color;

logic [11:0] symbol_xpos, symbol_xpos_q, symbol_xpos_2q;
logic [11:0] symbol_ypos, symbol_ypos_q, symbol_ypos_2q;

enum logic [STATE_BITS-1 :0] {
  IDLE,
  READ_SETTINGS,
  DRAW
} board_state;


// ----- Signal assignments -----
assign vcount_valid = in.vcount >= game_setup_cashe[BOARD_YPOS_REG_NUM] && in.vcount < game_setup_cashe[BOARD_YPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM];
assign hcount_valid = in.hcount >= game_setup_cashe[BOARD_XPOS_REG_NUM] && in.hcount < game_setup_cashe[BOARD_XPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM];

assign board_vcount = vcount_valid && hcount_valid ? in.vcount - game_setup_cashe[BOARD_YPOS_REG_NUM] : 11'h7_f_f;
assign board_hcount = vcount_valid && hcount_valid ? in.hcount - game_setup_cashe[BOARD_XPOS_REG_NUM] : 11'h7_f_f;

assign field_hcount = board_hcount[5:0];
assign field_vcount = board_vcount[5:0];

assign board_ind_x = board_hcount[9:6];
assign board_ind_y = board_vcount[9:6];

assign symbol_xpos = game_setup_cashe[BOARD_XPOS_REG_NUM] + board_ind_x * game_setup_cashe[FIELD_SIZE_REG_NUM];
assign symbol_ypos = game_setup_cashe[BOARD_YPOS_REG_NUM] + board_ind_y * game_setup_cashe[FIELD_SIZE_REG_NUM];

always_ff @(posedge clk) begin
  symbol_xpos_q <= symbol_xpos;
  symbol_ypos_q <= symbol_ypos;

  symbol_xpos_2q <= symbol_xpos_q;
  symbol_ypos_2q <= symbol_ypos_q;

  stage1_vga.rgb     <= in.rgb;
  stage1_vga.vcount  <= in.vcount;
  stage1_vga.vsync   <= in.vsync;
  stage1_vga.vblnk   <= in.vblnk;
  stage1_vga.hcount  <= in.hcount;
  stage1_vga.hsync   <= in.hsync;
  stage1_vga.hblnk   <= in.hblnk;

  stage2_vga.rgb     <= stage1_vga.rgb;
  stage2_vga.vcount  <= stage1_vga.vcount;
  stage2_vga.vsync   <= stage1_vga.vsync;
  stage2_vga.vblnk   <= stage1_vga.vblnk;
  stage2_vga.hcount  <= stage1_vga.hcount;
  stage2_vga.hsync   <= stage1_vga.hsync;
  stage2_vga.hblnk   <= stage1_vga.hblnk;
end


always_comb begin
  if (game_board_mem[board_ind_y][board_ind_x].mine_ind == 0) begin
    char_code = 0;
    num_color = 0;
  end
  else begin
    char_code = game_board_mem[board_ind_y][board_ind_x].mine_ind + 12'h30;
    case (game_board_mem[board_ind_y][board_ind_x].mine_ind)
      4'h1: num_color    = NUM_1;
      4'h2: num_color    = NUM_2;
      4'h3: num_color    = NUM_3;
      4'h4: num_color    = NUM_4;
      4'h5: num_color    = NUM_5;
      4'h6: num_color    = NUM_6;
      4'h7: num_color    = NUM_7;
      default: num_color = NUM_DEFAULT;
    endcase
  end
end


// Draw board logic
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

    burst_active      <= 1'b0;
    read_addr         <= 8'b0;
    settings_read_ctr <= 4'b0;
    read_en           <= 1'b0;
  end
  else begin
    out.vcount  <= stage2_vga.vcount;
    out.vsync   <= stage2_vga.vsync;
    out.vblnk   <= stage2_vga.vblnk;
    out.hcount  <= stage2_vga.hcount;
    out.hsync   <= stage2_vga.hsync;
    out.hblnk   <= stage2_vga.hblnk;

    case(board_state)
      IDLE: begin
        burst_active <= 1'b0;
        board_state  <= main_state == PLAY ? READ_SETTINGS : IDLE;
        read_en      <= main_state == PLAY;
        read_addr    <= 8'h0;
        out.rgb      <= stage2_vga.rgb;

        settings_read_ctr <= 4'b0;
      end
      READ_SETTINGS: begin
        out.rgb      <= stage2_vga.rgb;
        burst_active <= 1'b1;
        read_en      <= 1'b0;
        board_state  <= settings_read_ctr == SETTINGS_REG_NUM ? DRAW : READ_SETTINGS;

        if (read_ready && settings_read_ctr < SETTINGS_REG_NUM) begin

          game_setup_cashe[settings_read_ctr] <= read_data;
          settings_read_ctr                   <= settings_read_ctr + 1;

          read_addr <= (settings_read_ctr + 1) * 8'h2;
          read_en   <= 1'b1;
        end
      end
      DRAW: begin
        burst_active <= 1'b0;
        read_en      <= 1'b0;
        board_state  <= main_state == MENU ? IDLE : DRAW;
        out.rgb      <= draw_button();


        if (game_board_mem[board_ind_y][board_ind_x].mine && game_board_mem[board_ind_y][board_ind_x].defused)
          out.rgb <= draw_bomb();
        else if (game_board_mem[board_ind_y][board_ind_x].defused)
          if (game_board_mem[board_ind_y][board_ind_x].mine_ind == 0)
            out.rgb <= draw_uncovered();
          else
            out.rgb <= draw_number();
        else if (game_board_mem[board_ind_y][board_ind_x].flag)
          out.rgb <= draw_flag();

      end
      default: board_state <= IDLE;
    endcase
  end
end

// Auto read logic
always_ff @(posedge clk) begin
  if (rst || retry) begin
    auto_read_state <= WAIT;

    game_burst_active <= 1'b0;
    game_read_en    <= 1'b0;
    game_read_addr  <= 9'h00;

    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)  
        game_board_mem[i][j] <= 8'b0;
  end
  else begin
    case (auto_read_state)
      WAIT: begin
        if (in.vcount == 3 && in.hcount < 10) begin
          auto_read_state <= AUTO_READ;

          game_burst_active <= 1'b1;
          game_read_en      <= 1'b1;
          game_read_addr    <= 9'h00;
        end
      end
      AUTO_READ: begin
        game_read_en <= 1'b0;

        if (game_read_ready) begin
          game_board_mem[game_read_addr[7:4]][game_read_addr[3:0]] <= field_t'(game_read_data[7:0]);
          game_read_addr <= game_read_addr + 9'd1;
          game_read_en   <= 1'b1;
        end

        if (game_read_addr == 9'h100) begin
          game_read_en      <= 1'b0;
          game_burst_active <= 1'b0;
          auto_read_state   <= WAIT;
        end
      end
      default: auto_read_state <= WAIT;
    endcase
  end
end

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

wishbone_master u_board_master (
  .clk         (clk),
  .rst         (rst),

  .read_addr   (game_read_addr[7:0]),
  .read_data   (game_read_data),
  .read_en     (game_read_en),
  .read_ready  (game_read_ready),
  .burst_active(game_burst_active),

  .write_addr  ('0),
  .write_data  ('0),
  .write_en    ('0),
  .write_ready (),

  .wb_master   (game_board_wb)
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

function logic [11:0] draw_uncovered;
  if (field_hcount < game_setup_cashe[FIELD_SIZE_REG_NUM]-1 &&
      field_vcount < game_setup_cashe[FIELD_SIZE_REG_NUM]-1 &&
      field_hcount > 0 && field_vcount > 0 &&
      vcount_valid && hcount_valid) begin

    return BUTTON_BACK;
  end
  else if (vcount_valid && hcount_valid)
    return BUTTON_FRAME;
  else
    return in.rgb;
endfunction

function logic [11:0] draw_bomb;
  return bomb_vga.rgb;
endfunction

function logic [11:0] draw_flag;
  if (flag_vga.rgb != 12'h00F)
    return flag_vga.rgb;
  else
    return draw_button();
endfunction

function logic [11:0] draw_number();
  if (num_vga.rgb == NUM_1 ||
      num_vga.rgb == NUM_2 ||
      num_vga.rgb == NUM_3 ||
      num_vga.rgb == NUM_4 ||
      num_vga.rgb == NUM_5 ||
      num_vga.rgb == NUM_6 ||
      num_vga.rgb == NUM_7 )
    return num_vga.rgb;
  else
    return draw_uncovered();
endfunction


draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/bomb.data")
)
u_draw_bomb1 (
  .clk       (clk),
  .in        (stage2_vga),
  .out       (bomb_vga.out),
  .rect_x_pos(symbol_xpos_2q),
  .rect_y_pos(symbol_ypos_2q),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/flag_grey.data")
)
u_draw_flag1 (
  .clk       (clk),
  .in        (stage2_vga),
  .out       (flag_vga.out),
  .rect_x_pos(symbol_xpos_2q),
  .rect_y_pos(symbol_ypos_2q),
  .rst       (rst)
);


draw_char #(
  .PRESCALER (4),
  .OFFSET_X  (14),
  .OFFSET_Y  (3)//11
) u_draw_char (
  .clk      (clk),
  .rst      (rst),

  .char_code(char_code),
  .char_xpos(symbol_xpos_2q),
  .char_ypos(symbol_ypos_2q),
  .num_color(num_color),

  .in       (in),
  .out      (num_vga.out)
);

endmodule

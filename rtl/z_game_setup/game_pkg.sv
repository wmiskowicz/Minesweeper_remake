//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   The package containing game specific constants. 
 */
//////////////////////////////////////////////////////////////////////////////
 
package game_pkg;
  import vga_pkg::*;

  // ==== Definition types ====
  enum logic [2:0] {BANNER, MENU, PAUSE, PLAY, WIN, LOST, GAME_OVER} fsm_state;

// ======== EASY ========
  localparam [15:0] E_ROW_COLUMN_NUMBER = 6; 
  localparam [15:0] E_MINE_NUM          = 7;
  localparam [15:0] E_TIMER_SECONDS     = 60;
  localparam [15:0] E_FIELD_SIZE        = 64;
  localparam [15:0] E_BOARD_SIZE        = E_FIELD_SIZE * E_ROW_COLUMN_NUMBER; 
  localparam [15:0] E_BOARD_XPOS        = X_CENTER - (E_BOARD_SIZE / 2); 
  localparam [15:0] E_BOARD_YPOS        = Y_CENTER - (E_BOARD_SIZE / 2);

// ======== MEDIUM ========
  localparam [15:0] M_ROW_COLUMN_NUMBER = 8; 
  localparam [15:0] M_MINE_NUM          = 16;
  localparam [15:0] M_TIMER_SECONDS     = 100;
  localparam [15:0] M_FIELD_SIZE        = 64;
  localparam [15:0] M_BOARD_SIZE        = M_FIELD_SIZE * M_ROW_COLUMN_NUMBER; 
  localparam [15:0] M_BOARD_XPOS        = X_CENTER - (M_BOARD_SIZE / 2); 
  localparam [15:0] M_BOARD_YPOS        = Y_CENTER - (M_BOARD_SIZE / 2);

// ======== HARD ========
  localparam [15:0] H_ROW_COLUMN_NUMBER = 11; 
  localparam [15:0] H_MINE_NUM          = 20;
  localparam [15:0] H_TIMER_SECONDS     = 120;
  localparam [15:0] H_FIELD_SIZE        = 64;
  localparam [15:0] H_BOARD_SIZE        = H_FIELD_SIZE * H_ROW_COLUMN_NUMBER; 
  localparam [15:0] H_BOARD_XPOS        = X_CENTER - (H_BOARD_SIZE / 2); 
  localparam [15:0] H_BOARD_YPOS        = Y_CENTER - (H_BOARD_SIZE / 2);

// ======== REGISTER NUM ========
  localparam [15:0] ROW_COLUMN_NUMBER_REG_NUM = 0; 
  localparam [15:0] MINE_NUM_REG_NUM          = 1;
  localparam [15:0] TIMER_SECONDS_REG_NUM     = 2;
  localparam [15:0] FIELD_SIZE_REG_NUM        = 3;
  localparam [15:0] BOARD_SIZE_REG_NUM        = 4; 
  localparam [15:0] BOARD_XPOS_REG_NUM        = 5; 
  localparam [15:0] BOARD_YPOS_REG_NUM        = 6;
  localparam [15:0] GAMES_WON_REG_NUM         = 7;
  localparam [15:0] GAMES_LOST_REG_NUM        = 8;


endpackage

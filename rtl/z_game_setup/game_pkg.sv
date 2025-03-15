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
  typedef enum logic [2:0] {MENU, PAUSE, PLAY, WIN, LOST, GAME_OVER} fsm_state_t;

// ======== EASY ========
  localparam E_ROW_COLUMN_NUMBER = 8; 
  localparam E_MINE_NUM          = 19;
  localparam E_TIMER_SECONDS     = 45;
  localparam E_FIELD_SIZE        = 64;
  localparam E_BOARD_SIZE        = E_FIELD_SIZE * E_ROW_COLUMN_NUMBER; 
  localparam E_BOARD_XPOS        = X_CENTER - (E_BOARD_SIZE / 2); 
  localparam E_BOARD_YPOS        = Y_CENTER - (E_BOARD_SIZE / 2);

// ======== MEDIUM ========
  localparam M_ROW_COLUMN_NUMBER = 10; 
  localparam M_MINE_NUM          = 30;
  localparam M_TIMER_SECONDS     = 50;
  localparam M_FIELD_SIZE        = 64;
  localparam M_BOARD_SIZE        = M_FIELD_SIZE * M_ROW_COLUMN_NUMBER; 
  localparam M_BOARD_XPOS        = X_CENTER - (M_BOARD_SIZE / 2); 
  localparam M_BOARD_YPOS        = Y_CENTER - (M_BOARD_SIZE / 2);

// ======== HARD ========
  localparam H_ROW_COLUMN_NUMBER = 15; 
  localparam H_MINE_NUM          = 40;
  localparam H_TIMER_SECONDS     = 70;
  localparam H_FIELD_SIZE        = 64;
  localparam H_BOARD_SIZE        = H_FIELD_SIZE * H_ROW_COLUMN_NUMBER; 
  localparam H_BOARD_XPOS        = X_CENTER - (H_BOARD_SIZE / 2); 
  localparam H_BOARD_YPOS        = Y_CENTER - (H_BOARD_SIZE / 2);


endpackage

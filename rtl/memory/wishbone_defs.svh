`ifndef WISHBONE_DEFS_SVH
`define WISHBONE_DEFS_SVH

typedef enum logic {
    IDLE,
    BUS_WAIT
} master_state_t;

typedef struct packed {
  logic [15:0] row_column_number; 
  logic [15:0] mine_number;       
  logic [15:0] timer_seconds;     
  logic [15:0] field_size;        
  logic [15:0] board_size;
  logic [15:0] board_xpos;
  logic [15:0] board_ypos;
  logic [15:0] games_won;
  logic [15:0] games_lost;
} game_setup_mem_t;

typedef struct packed {
  logic        mine;
  logic        flag;
  logic        defused;
  logic [3:0]  mine_ind;
  logic        placeholder;
} field_t;

`endif

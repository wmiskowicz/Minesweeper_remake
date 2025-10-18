`ifndef DEFUSER_DEFS_SVH
`define DEFUSER_DEFS_SVH

typedef enum logic [2:0] {
  AR_IDLE,
  AR_READ_SETTINGS,
  AR_READ_BOARD,
  AR_DONE
} auto_read_state_t;

typedef enum logic [1:0] {
  AW_WAIT,
  AW_WRITE
} auto_write_state_t;

typedef enum logic [2:0] {
  DEF_IDLE,
  DEF_READ_BOARD,
  DEF_WAIT_FOR_MOUSE,
  DEF_WRITE_MINE_IND,
  DEFUSE,
  DEF_INSPECT_BOARD,
  DEF_WIN_CHECK,
  DEF_GAME_OVER
} defuser_state_t;

`endif

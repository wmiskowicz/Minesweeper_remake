`ifndef DEFUSER_DEFS_SVH
`define DEFUSER_DEFS_SVH

enum logic [2:0] {
  IDLE,
  READ_SETTINGS,
  READ_BOARD,
  DONE
} auto_read_state;

enum logic [1:0] {
  WAIT,
  AUTO_WRITE
} auto_write_state;

enum logic [2:0] {
  DEF_IDLE,
  DEF_READ_BOARD,
  DEF_WAIT_FOR_MOUSE,
  DEF_WRITE_MINE_IND,
  DEFUSE,
  DEF_WIN_CHECK
} defuser_state;

`endif

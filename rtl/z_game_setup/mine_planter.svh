`ifndef MINE_PLANTER_SVH
`define MINE_PLANTER_SVH

typedef enum logic [2:0] {
  PLANTER_IDLE,
  PLANTER_READ_SETTINGS,
  PLANTER_PLANT,
  PLANTER_WRITE_BOARD,
  PLANTER_DONE
} planter_state_t;

`endif 

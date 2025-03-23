//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game. 
 */
//////////////////////////////////////////////////////////////////////////////
`include "wishbone_defs.svh"
module top_memory (
  input wire clk100MHz,
  input wire clk74MHz,
  input wire clk40MHz,
  input wire rst,

  wishbone_if.master write1_wb,
  wishbone_if.master write2_wb,
  wishbone_if.slave read_wb
);

wishbone_if write_if();


wishbone_board_mem #(
  .BOARD_SIZE(16)
)
u_wishbone_board_mem (
  .clk     (clk100MHz),
  .rst     (rst),
  .slave_rd(read_wb),
  .slave_wr(write_if.slave)
);

wishbone_arbiter u_wishbone_arbiter (
  .clk     (clk100MHz),
  .rst     (rst),

  .master_prior(write1_wb),
  .master_2(write2_wb),
  .slave_if(write_if.slave)
);
  
endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game. 
 */
//////////////////////////////////////////////////////////////////////////////
`include "wishbone_defs.svh"
module top_memory (
  input wire clk74MHz,
  input wire rst,

  wishbone_if.slave write1_wb,
  wishbone_if.slave write2_wb,
  wishbone_if.slave read_wb
);

wishbone_if selected_wb_if();


wishbone_board_mem #(
  .BOARD_SIZE(16)
)
u_wishbone_board_mem (
  .clk     (clk74MHz),
  .rst     (rst),
  .slave(selected_wb_if.slave)
);

wishbone_arbiter u_wishbone_arbiter (
  .clk     (clk74MHz),
  .rst     (rst),

  .master_prior (write1_wb),
  .master_2     (write2_wb),
  .master_3     (read_wb),
  .slave_if     (selected_wb_if.master)
);
  
endmodule

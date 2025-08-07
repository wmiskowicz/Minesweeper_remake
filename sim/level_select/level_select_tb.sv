//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   level_select_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Testbench for the level select module.
 */
//////////////////////////////////////////////////////////////////////////////

module level_select_tb;

import logger_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 10ns;

localparam logic [11:0] XPOS_LOW = 12'h2040;   
localparam logic [11:0] XPOS_HI =  12'h2F90;  

localparam logic [11:0] YPOS_EZ_LO =  12'h1310;   
localparam logic [11:0] YPOS_EZ_HI =  12'h1780;   
localparam logic [11:0] YPOS_MD_LO =  12'h1930;   
localparam logic [11:0] YPOS_MD_HI =  12'h1DA0;     
localparam logic [11:0] YPOS_HD_LO =  12'h1F30;   
localparam logic [11:0] YPOS_HD_HI =  12'h2390; 

// ----- Local variables -----
logic clk;
logic rst;

logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
logic        left;
logic [1:0] level;

// ----- Signal interfaces -----
wishbone_if game_set1_if();
wishbone_if game_set2_if();
wishbone_if game_set3_if();



level_select dut(
  .clk    (clk),
  .rst    (rst),

  .left       (left),
  .mouse_xpos (mouse_xpos),
  .mouse_ypos (mouse_ypos),
  .level      (level)
);

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
  void'(logger::init());
  InitReset();
  WaitClocks(100);
  mouse_xpos = XPOS_LOW + 10;
  mouse_ypos = YPOS_EZ_LO + 10;
  left = 1'b1;
  WaitClocks(100);
  `check_eq(level, 2'd1);
  mouse_xpos = XPOS_LOW + 10;
  mouse_ypos = YPOS_MD_LO + 10;
  WaitClocks(100);
  `check_eq(level, 2'd2);
  
  $finish();
end



task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
  WaitClocks(10);
endtask

endmodule

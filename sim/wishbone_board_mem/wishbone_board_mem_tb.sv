//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   wishbone_board_mem.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module wishbone_board_mem.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
 
module wishbone_board_mem_tb;

import logger_pkg::*;

// ----- Local parameters -----
localparam CLK_PERIOD = 14ns;
localparam BOARD_SIZE = 16;

// ----- Local variables -----
logic clk;
logic rst;

// ----- Signal interfaces -----
wishbone_if board_wb_if();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

wishbone_board_mem dut (
  .clk(clk),
  .rst(rst),
  .slave(board_wb_if.slave)
);

initial begin
  void'(logger::init());
  board_wb_if.cyc_o = 1'b0;
  board_wb_if.stb_o = 1'b0;
  board_wb_if.we_o = 1'b0;
  board_wb_if.adr_o = 8'b0;
  board_wb_if.dat_o = 16'b0;
  InitReset();

  `log_info("Starting wishbone_board_mem tests");


  // Test 1: Verify reset behavior
  `log_info("Test 1: Verifying reset clears memory");
  for (int i = 0; i < BOARD_SIZE; i++) begin
    for (int j = 0; j < BOARD_SIZE; j++) begin
      board_wb_if.adr_o = {i[3:0], j[3:0]};
      board_wb_if.cyc_o = 1'b1;
      board_wb_if.stb_o = 1'b1;
      WaitClocks(1);
      if (board_wb_if.dat_i[7:0] != 8'b0) begin
        `log_err($sformatf("Memory not cleared at [%0d][%0d]: %02x", i, j, board_wb_if.dat_i[7:0]));
      end
      board_wb_if.cyc_o = 1'b0;
      board_wb_if.stb_o = 1'b0;
    end
  end
  `log_info("Reset test completed");


// Test 2: Verify write and read operations
`log_info("Test 2: Verifying write and read operations");
for (int i = 0; i < BOARD_SIZE; i++) begin
  for (int j = 0; j < BOARD_SIZE; j++) begin
    // Write operation
    board_wb_if.adr_o = {i[3:0], j[3:0]};
    board_wb_if.dat_o = {8'b0, 8'(i*BOARD_SIZE + j)};
    board_wb_if.we_o = 1'b1;
    board_wb_if.cyc_o = 1'b1;
    board_wb_if.stb_o = 1'b1;
    WaitClocks(1);

    // Read operation
    board_wb_if.we_o = 1'b0;
    WaitClocks(3);
    
    `check_eq(board_wb_if.dat_i[15:8], 8'b0, 
             "Upper 8 bits should always be 0");
    
    `check_eq(board_wb_if.dat_i[7:0], (i*BOARD_SIZE + j),
             $sformatf("Data mismatch at [%0d][%0d] got %h, expected %h", i, j, board_wb_if.dat_i[7:0], (i*BOARD_SIZE + j)));

    board_wb_if.cyc_o = 1'b0;
    board_wb_if.stb_o = 1'b0;
    WaitClocks(1);
  end
end
`log_info("Write/read test completed");


  // Test 3: Verify wishbone protocol signals
  `log_info("Test 4: Verifying wishbone protocol signals");
  // Check ack is only asserted when cyc and stb are high
  board_wb_if.cyc_o = 1'b0;
  board_wb_if.stb_o = 1'b1;
  WaitClocks(1);
  if (board_wb_if.ack_i) `log_err("Ack asserted without cyc");

  board_wb_if.cyc_o = 1'b1;
  board_wb_if.stb_o = 1'b0;
  WaitClocks(1);
  if (board_wb_if.ack_i) `log_err("Ack asserted without stb");

  board_wb_if.cyc_o = 1'b1;
  board_wb_if.stb_o = 1'b1;
  WaitClocks(1);
  if (!board_wb_if.ack_i) `log_err("Ack not asserted with cyc and stb");

  board_wb_if.cyc_o = 1'b0;
  board_wb_if.stb_o = 1'b0;
  `log_info("Wishbone protocol test completed");



  // Test 5: Verify stall is always low
  `log_info("Test 5: Verifying stall signal");
  if (board_wb_if.stall_i !== 1'b0) begin
    `log_err("Stall signal not always low");
  end
  `log_info("Stall signal test completed");

  `log_info("All tests completed");
  $finish();
end


task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

endmodule

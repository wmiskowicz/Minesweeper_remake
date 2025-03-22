`timescale 1ns / 1ps

// Include VUnit Macros
`include "vunit_defines.svh"

module board_mem_tb;
  logic clk = 0;
  logic rst = 0;
  localparam CLK_PERIOD = 10;

  // Clock Generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Instantiate DUT
  parameter BOARD_SIZE = 16;

  wishbone_if slave_wr();
  wishbone_if slave_rd();

  wishbone_board_mem #(
    .BOARD_SIZE(BOARD_SIZE)
  )
  u_wishbone_board_mem (
    .clk     (clk),
    .rst     (rst),
    .slave_rd(slave_rd.slave),
    .slave_wr(slave_wr.slave)
  );

  // TEST SUITE
  `TEST_SUITE("Memory_Test_Suite")

    // TEST SUITE SETUP (Runs ONCE before all test cases)
    `TEST_SUITE_SETUP begin
      $display("[INFO] Test Suite Setup - Initializing Testbench");
      rst_n = 0;
      #20;
      rst_n = 1;
    end

    // TEST CASE 1
    `TEST_CASE("TC001") begin
      $display("[TEST] TC001 - Example test case");
    end

    // TEST CASE 2
    `TEST_CASE("TC002") begin
      $display("[TEST] TC002 - Another test case");
    end

  `TEST_SUITE_END
endmodule

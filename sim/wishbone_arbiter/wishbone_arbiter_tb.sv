//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   wishbone_arbiter_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module wishbone_arbiter.
 */
//////////////////////////////////////////////////////////////////////////////

`include "../../rtl/memory/wishbone_defs.svh"
`include "../../XVunit/internals/verilog/xvunit_defines.svh"

module wishbone_arbiter_tb;

  import game_pkg::*;

  // ----- Local parameters -----
  localparam CLK_PERIOD = 14ns;

  // ----- Local variables -----
  logic clk;
  logic rst;

  // ----- Signal interfaces -----
  wishbone_if master_prior_if();
  wishbone_if master_2_if();
  wishbone_if master_3_if();
  wishbone_if slave_if();

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  wishbone_arbiter dut (
    .clk          (clk),
    .rst          (rst),

    .master_prior (master_prior_if.slave),
    .master_2     (master_2_if.slave),
    .master_3     (master_3_if.slave),
    .slave_if     (slave_if.master)
  );

  always @(posedge clk) begin
    if(slave_if.stb_o)
      slave_if.ack_i <= 1'b1;
    else
      slave_if.ack_i <= 1'b0;
  end

  `TEST_SUITE_BEGIN

        `TEST_SUITE_SETUP begin
          $display($sformatf("Starting test suite at %t", $time));
        end

        `TEST_CASE_SETUP begin
          slave_if.stall_i = 1'b0;
          master_prior_if.stall_i = 1'b0;
          master_2_if.stall_i = 1'b0;
          master_3_if.stall_i = 1'b0;

          master_prior_if.adr_o = '0;
          master_prior_if.dat_o = '0;
          master_prior_if.we_o  = '0;
          master_prior_if.stb_o = '0;
          master_prior_if.cyc_o = '0;

          master_2_if.adr_o = '0;
          master_2_if.dat_o = '0;
          master_2_if.we_o  = '0;
          master_2_if.stb_o = '0;
          master_2_if.cyc_o = '0;

          master_3_if.adr_o = '0;
          master_3_if.dat_o = '0;
          master_3_if.we_o  = '0;
          master_3_if.stb_o = '0;
          master_3_if.cyc_o = '0;

          InitReset();
          WaitClocks(2);
        end

        `TEST_CASE("TC000") begin
          $display("Testbench compiled successfully");
        end

        `TEST_CASE("TC001") begin
          $display("Verify that during concurrent 3 requests master_prior is selected");

          master_prior_if.adr_o = 8'h10;
          master_prior_if.dat_o = 16'hA5A5;
          master_prior_if.we_o  = 1'b1;
          master_prior_if.stb_o = 1'b1;
          master_prior_if.cyc_o = 1'b1;

          master_2_if.adr_o = 8'h20;
          master_2_if.dat_o = 16'h5A5A;
          master_2_if.we_o  = 1'b1;
          master_2_if.stb_o = 1'b1;
          master_2_if.cyc_o = 1'b1;

          master_3_if.adr_o = 8'h30;
          master_3_if.dat_o = 16'h1234;
          master_3_if.we_o  = 1'b1;
          master_3_if.stb_o = 1'b1;
          master_3_if.cyc_o = 1'b1;

          WaitClocks(2);

          `CHECK_EQUAL(slave_if.adr_o, master_prior_if.adr_o);
          `CHECK_EQUAL(slave_if.dat_o, master_prior_if.dat_o);
          `CHECK_EQUAL(slave_if.we_o, master_prior_if.we_o);
          `CHECK_EQUAL(master_2_if.stall_i, 1'b1);
          `CHECK_EQUAL(master_3_if.stall_i, 1'b1);
        end

        `TEST_CASE("TC002") begin
          $display("Verify that during concurrent 2 requests master_2 is selected prior to master_3");

          master_prior_if.stb_o = 1'b0;
          master_prior_if.cyc_o = 1'b0;

          master_2_if.adr_o = 8'h20;
          master_2_if.dat_o = 16'h5A5A;
          master_2_if.we_o  = 1'b1;
          master_2_if.stb_o = 1'b1;
          master_2_if.cyc_o = 1'b1;

          master_3_if.adr_o = 8'h30;
          master_3_if.dat_o = 16'h1234;
          master_3_if.we_o  = 1'b1;
          master_3_if.stb_o = 1'b1;
          master_3_if.cyc_o = 1'b1;

          WaitClocks(2);
          `CHECK_EQUAL(slave_if.adr_o, master_2_if.adr_o);
          `CHECK_EQUAL(slave_if.dat_o, master_2_if.dat_o);
          `CHECK_EQUAL(slave_if.we_o,  master_2_if.we_o);

        end

        `TEST_CASE("TC003") begin
          $display("Verify that master_3 is selected when others are not requesting");

          master_prior_if.stb_o = 1'b0;
          master_prior_if.cyc_o = 1'b0;

          master_2_if.stb_o = 1'b0;
          master_2_if.cyc_o = 1'b0;

          master_3_if.adr_o = 8'h30;
          master_3_if.dat_o = 16'h1234;
          master_3_if.we_o  = 1'b1;
          master_3_if.stb_o = 1'b1;
          master_3_if.cyc_o = 1'b1;

          WaitClocks(2);

          `CHECK_EQUAL(slave_if.adr_o, master_3_if.adr_o);
          `CHECK_EQUAL(slave_if.dat_o, master_3_if.dat_o);
          `CHECK_EQUAL(slave_if.we_o,  master_3_if.we_o);
        end

        `TEST_CASE("TC004") begin
          $display("Verify that master_prior is not able to interrupt ongoing transaction");

          master_3_if.adr_o = 8'h30;
          master_3_if.dat_o = 16'h1234;
          master_3_if.we_o  = 1'b1;
          master_3_if.stb_o = 1'b1;
          master_3_if.cyc_o = 1'b1;

          WaitClocks(2);
          master_prior_if.adr_o = 8'h10;
          master_prior_if.dat_o = 16'hA5A5;
          master_prior_if.we_o  = 1'b1;
          master_prior_if.stb_o = 1'b1;
          master_prior_if.cyc_o = 1'b1;

          master_2_if.adr_o = 8'h20;
          master_2_if.dat_o = 16'h5A5A;
          master_2_if.we_o  = 1'b1;
          master_2_if.stb_o = 1'b1;
          master_2_if.cyc_o = 1'b1;

          // master_3 is still selected
          WaitClocks(2);
          `CHECK_EQUAL(slave_if.adr_o, master_3_if.adr_o);
          `CHECK_EQUAL(slave_if.dat_o, master_3_if.dat_o);
          `CHECK_EQUAL(slave_if.we_o,  master_3_if.we_o);


          WaitClocks(2);
          master_3_if.cyc_o = 1'b0;
          master_3_if.stb_o = 1'b0;
          
          // master_prior is selected over master_2
          WaitClocks(2);
          `CHECK_EQUAL(slave_if.adr_o, master_prior_if.adr_o);
          `CHECK_EQUAL(slave_if.dat_o, master_prior_if.dat_o);
          `CHECK_EQUAL(slave_if.we_o,  master_prior_if.we_o);
        end

      `TEST_SUITE_END

  task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
    $display("Reset released");
  endtask

endmodule

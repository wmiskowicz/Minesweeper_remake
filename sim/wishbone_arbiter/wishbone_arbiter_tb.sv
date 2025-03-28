`include "../../rtl/memory/wishbone_defs.svh"
module wishbone_arbiter_tb;

  import logger_pkg::*;
  import game_pkg::*;

  logic clk;
  logic rst;

  wishbone_if master_prior_if();
  wishbone_if master_2_if();
  wishbone_if master_3_if();
  wishbone_if slave_if();

  localparam CLK_PERIOD = 25ns;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  wishbone_arbiter dut (
    .clk      (clk),
    .rst      (rst),
    .master_prior (master_prior_if.master),
    .master_2 (master_2_if.master),
    .master_3 (master_3_if.master),
    .slave_if (slave_if.slave)
  );

  // Simple slave model - always ready to respond
  always @(posedge clk) begin
    if(slave_if.stb_o) slave_if.ack_i <= 1'b1;
    else slave_if.ack_i <= 1'b0;
  end

  initial begin
    void'(logger::init());
    // Initialize all stall signals
    slave_if.stall_i = 1'b0;
    master_prior_if.stall_i = 1'b0;
    master_2_if.stall_i = 1'b0;
    master_3_if.stall_i = 1'b0;
    
    // Initialize all master outputs
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
    `log_info($sformatf("Starting test at, %t", $time));
    WaitClocks(2);

    // Test 1: Check priority when all masters request simultaneously
`log_info("Test 1: Priority check with all masters requesting");
    // First make sure no masters are active
    master_prior_if.cyc_o = 1'b0;
    master_prior_if.stb_o = 1'b0;
    master_2_if.cyc_o = 1'b0;
    master_2_if.stb_o = 1'b0;
    master_3_if.cyc_o = 1'b0;
    master_3_if.stb_o = 1'b0;
    WaitClocks(1);
    
    // Then activate all masters simultaneously
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
    
    WaitClocks(2);  // Wait one cycle for arbitration
    
    // Check that priority master gets access
    `check_eq(slave_if.adr_o, master_prior_if.adr_o);
    `check_eq(slave_if.dat_o, master_prior_if.dat_o);
    `check_eq(slave_if.we_o, master_prior_if.we_o);
    
    // Check that other masters are stalled
    `check_eq(master_2_if.stall_i, 1'b1);
    `check_eq(master_3_if.stall_i, 1'b1);

    // Test 2: Check master 2 gets access when priority master releases
    `log_info("Test 2: Master 2 access after priority master");
    WaitClocks(2);
    master_prior_if.cyc_o = 1'b0;
    master_prior_if.stb_o = 1'b0;
    WaitClocks(2);
    `check_eq(slave_if.adr_o, master_2_if.adr_o);
    `check_eq(slave_if.dat_o, master_2_if.dat_o);
    `check_eq(slave_if.we_o, master_2_if.we_o);

    // Test 3: Check master 3 gets access when higher priority masters release
    `log_info("Test 3: Master 3 access after higher priority masters");
    WaitClocks(2);
    master_2_if.cyc_o = 1'b0;
    master_2_if.stb_o = 1'b0;
    WaitClocks(2);
    `check_eq(slave_if.adr_o, master_3_if.adr_o);
    `check_eq(slave_if.dat_o, master_3_if.dat_o);
    `check_eq(slave_if.we_o, master_3_if.we_o);

    // Test 4: Check priority master can interrupt lower priority master
    `log_info("Test 4: Priority master interrupt");
    WaitClocks(1);
    master_prior_if.adr_o = 8'h40;
    master_prior_if.dat_o = 16'hDEAD;
    master_prior_if.we_o  = 1'b1;
    master_prior_if.stb_o = 1'b1;
    master_prior_if.cyc_o = 1'b1;
    WaitClocks(1);
    `check_eq(slave_if.adr_o, master_3_if.adr_o);
    WaitClocks(2); // Let master 3 finish
    master_3_if.cyc_o = 1'b0;
    master_3_if.stb_o = 1'b0;
    WaitClocks(2);
    `check_eq(slave_if.adr_o, master_prior_if.adr_o);

    // Cleanup
    WaitClocks(2);
    master_prior_if.cyc_o = 1'b0;
    master_prior_if.stb_o = 1'b0;
    WaitClocks(5);

    `log_info("All tests completed");
    #50 $finish;
  end

  task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
    `log_info("Reset released");
  endtask

endmodule
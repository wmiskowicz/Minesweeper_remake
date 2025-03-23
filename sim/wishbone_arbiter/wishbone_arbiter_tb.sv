`include "../../rtl/memory/wishbone_defs.svh"
module wishbone_arbiter_tb;

  import logger_pkg::*;
  import game_pkg::*;

  logic clk;
  logic rst;

  wishbone_if master_0_if();
  wishbone_if master_1_if();
  wishbone_if slave_if();

  localparam CLK_PERIOD = 25ns;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  wishbone_arbiter dut (
    .clk      (clk),
    .rst      (rst),
    .master_prior (master_0_if.master),
    .master_2 (master_1_if.master),
    .slave_if (slave_if.slave)
  );

  always @(posedge clk) begin
    if(slave_if.stb_o) slave_if.ack_i <= 1'b1;
    else slave_if.ack_i <= 1'b0;
  end

  initial begin
    void'(logger::init());
    slave_if.stall_i = 1'b0;
    master_0_if.stall_i = 1'b0;
    master_1_if.stall_i = 1'b0;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    WaitClocks(2);

    // #1 check if when simultaneously arriving request if one master has a priority
    master_0_if.adr_o = 32'h00000010;
    master_0_if.dat_o = 32'hA5A5A5A5;
    master_0_if.we_o  = 1'b1;
    master_0_if.stb_o = 1'b1;
    master_0_if.cyc_o = 1'b1;
    master_1_if.adr_o = 32'h00000020;
    master_1_if.dat_o = 32'h5A5A5A5A;
    master_1_if.we_o  = 1'b1;
    master_1_if.stb_o = 1'b1;
    master_1_if.cyc_o = 1'b1;
    WaitClocks(1);
    `check_eq(slave_if.adr_o, master_0_if.adr_o);
    `check_eq(slave_if.dat_o, master_0_if.dat_o);

    // #2 check if second waits until prior one finishes
    WaitClocks(5);
    master_0_if.cyc_o = 1'b0;
    master_0_if.stb_o = 1'b0;
    WaitClocks(1);
    `check_eq(slave_if.adr_o, master_1_if.adr_o);
    `check_eq(slave_if.dat_o, master_1_if.dat_o);

    // #3 check if he performed pending action
    WaitClocks(5);
    master_1_if.cyc_o = 1'b0;
    master_1_if.stb_o = 1'b0;
    WaitClocks(5);

    #50 $finish;
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

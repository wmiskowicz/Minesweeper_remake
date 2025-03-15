//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Wishbone master testbench
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for wishbone master.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
module wishbone_master_tb;

  import logger_pkg::*;

  logic clk;
  logic rst;

  logic burst_active;
  logic [7:0] write_data;
  logic [7:0] write_addr;
  logic write_en;
  logic write_ready;

  logic [7:0] read_data;
  logic [7:0] read_addr;
  logic read_en;
  logic read_ready;

  wishbone_if wb_master();
  
  localparam CLK_PERIOD = 25ns;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end
    
  wishbone_master dut (
    .clk      (clk),
    .rst      (rst),

    .burst_active (burst_active),
    .write_data   (write_data),
    .write_addr   (write_addr),
    .write_en     (write_en),
    .write_ready  (write_ready),

    .read_data    (read_data),
    .read_addr    (read_addr),
    .read_en      (read_en),
    .read_ready   (read_ready),

    .wb_master(wb_master)
  );
        
  initial begin
    void'(logger::init());
    clk = 0;
    burst_active = 0;
    write_data = 0;
    write_addr = 0;
    write_en = 0;
    read_addr = 0;
    read_en = 0;
    wb_master.ack_i = 1'b0;
    wb_master.stall_i = 1'b1;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));

    // Start write burst
    burst_active = 1'b1;
    write_addr   = 8'h80;
    write_data   = 8'hAA;
    write_en     = 1'b1;
    WaitClocks(1);
    write_en = 1'b0;
    WaitClocks(10);
    `check_eq(dut.master_state, BUS_WAIT)
    wb_master.stall_i = 1'b0;
    wb_master.ack_i = 1'b1;
    WaitClocks(1);
    `check_eq(dut.master_state, IDLE)
    wb_master.ack_i = 0;
    wb_master.stall_i = 1'b1;

    WaitClocks(15);

    // Start read burst
    read_addr = 8'h10;
    read_en   = 1'b1;
    WaitClocks(15);
    read_en = 0;
    `check_eq(dut.master_state, BUS_WAIT)
    wb_master.stall_i = 1'b0;
    wb_master.ack_i = 1'b1;
    wb_master.dat_i = 8'h55;
    WaitClocks(1);
    wb_master.ack_i = 0;
    `check_eq(read_ready, 1'b1);
    `check_eq(read_data, 8'h55);

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
  
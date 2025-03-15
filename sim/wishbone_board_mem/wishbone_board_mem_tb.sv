`include "../../rtl/memory/wishbone_defs.svh"
module wishbone_board_mem_tb;

  import logger_pkg::*;

  logic clk;
  logic rst;

  logic [7:0] write_data;
  logic [7:0] write_addr;
  logic write_en;
  logic write_ready;

  logic [7:0] read_data;
  logic [7:0] read_addr;
  logic read_en;
  logic read_ready;

  wishbone_if master_w();
  wishbone_if master_r();

  localparam CLK_PERIOD = 25ns;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end
    
  wishbone_board_mem dut (
    .clk(clk),
    .rst(rst),
    .master_w(master_w.slave),
    .master_r(master_r.slave)
  );
        
  initial begin
    void'(logger::init());
    clk = 0;
    write_data = 0;
    write_addr = 0;
    write_en = 0;
    read_addr = 0;
    read_en = 0;
    master_r.cyc_o = 1'b0;
    master_r.stb_o = 1'b0;
    master_w.cyc_o = 1'b0;
    master_w.stb_o = 1'b0;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));

    // Master W tries to write while Master R is reading
    read_addr = 8'h10;
    read_en   = 1'b1;
    master_r.cyc_o = 1'b1;
    master_r.stb_o = 1'b1;
    WaitClocks(2);
    `check_eq(dut.grant_r, 1'b1);
    write_addr = 8'h20;
    write_data = 8'hAA;
    write_en   = 1'b1;
    master_w.cyc_o = 1'b1;
    master_w.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(master_w.stall_i, 1'b1);
    read_en = 0;
    master_r.cyc_o = 1'b0;
    master_r.stb_o = 1'b0;
    WaitClocks(1);
    `check_eq(dut.grant_w, 1'b1);
    WaitClocks(1);
    WaitClocks(1);
    write_en = 0;
    master_w.cyc_o = 1'b0;
    master_w.stb_o = 1'b0;

    WaitClocks(10);

    // Master R tries to read while Master W is writing
    write_addr = 8'h30;
    write_data = 8'hBB;
    write_en   = 1'b1;
    master_w.cyc_o = 1'b1;
    master_w.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(dut.grant_w, 1'b1);
    read_addr = 8'h40;
    read_en   = 1'b1;
    master_r.cyc_o = 1'b1;
    master_r.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(master_r.stall_i, 1'b1);
    write_en = 0;
    master_w.cyc_o = 1'b0;
    master_w.stb_o = 1'b0;
    WaitClocks(1);
    `check_eq(dut.grant_r, 1'b1);
    WaitClocks(1);
    WaitClocks(1);
    read_en = 0;
    master_r.cyc_o = 1'b0;
    master_r.stb_o = 1'b0;

    WaitClocks(20);
    $finish;
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
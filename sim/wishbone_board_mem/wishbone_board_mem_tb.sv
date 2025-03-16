`include "../../rtl/memory/wishbone_defs.svh"
module wishbone_board_mem_tb;

  import logger_pkg::*;

  logic clk;
  logic rst;

  wishbone_if write_wb(.CLK_I(clk), .RST_I(rst));
  wishbone_if read_wb(.CLK_I(clk), .RST_I(rst));

  localparam CLK_PERIOD = 25ns;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end
    
  wishbone_board_mem dut (
    .clk(clk),
    .rst(rst),
    .slave_wr(write_wb.slave),
    .slave_rd(read_wb.slave)
  );
  
  initial begin
    void'(logger::init());
    read_wb.cyc_o = 1'b0;
    read_wb.stb_o = 1'b0;
    write_wb.cyc_o = 1'b0;
    write_wb.stb_o = 1'b0;
    InitReset();
    
    `log_info($sformatf("Starting test at, %t", $time));

    `log_info("Running TEST_WRITE_WHILE_READ");
    read_wb.cyc_o = 1'b1;
    read_wb.stb_o = 1'b1;
    WaitClocks(2);
    `check_eq(dut.grant_r, 1'b1);
    write_wb.cyc_o = 1'b1;
    write_wb.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(write_wb.stall_i, 1'b1);
    read_wb.cyc_o = 1'b0;
    read_wb.stb_o = 1'b0;
    WaitClocks(1);
    `check_eq(dut.grant_w, 1'b1);
    WaitClocks(1);
    WaitClocks(1);
    write_wb.cyc_o = 1'b0;
    write_wb.stb_o = 1'b0;
    WaitClocks(10);


    `log_info("Running TEST_READ_WHILE_WRITE");
    write_wb.cyc_o = 1'b1;
    write_wb.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(dut.grant_w, 1'b1);
    read_wb.cyc_o = 1'b1;
    read_wb.stb_o = 1'b1;
    WaitClocks(1);
    `check_eq(read_wb.stall_i, 1'b1);
    write_wb.cyc_o = 1'b0;
    write_wb.stb_o = 1'b0;
    WaitClocks(1);
    `check_eq(dut.grant_r, 1'b1);
    WaitClocks(1);
    WaitClocks(1);
    read_wb.cyc_o = 1'b0;
    read_wb.stb_o = 1'b0;
    WaitClocks(20);

    write_wb.cyc_o = 1'b1;
    write_wb.stb_o = 1'b1;
    write_wb.adr_o = 8'h33;
    write_wb.dat_o = 8'h55;
    write_wb.we_o  = 1'b1;
    WaitClocks(4);
    `check_eq(dut.row_w, 4'd3);
    `check_eq(dut.col_w, 4'd3);
    `check_eq(dut.grant_w, 1'b1);
    `check_eq(write_wb.stall_i, 1'b0);
    `check_eq(dut.board_mem[3][3], 8'h55);
    write_wb.cyc_o = 1'b0;
    write_wb.stb_o = 1'b0;
    write_wb.we_o  = 1'b0;

    WaitClocks(20);
    read_wb.cyc_o = 1'b1;
    read_wb.stb_o = 1'b1;
    read_wb.adr_o = 8'h33;
    read_wb.we_o  = 1'b0;
    WaitClocks(2);
    `check_eq(dut.row_r, 4'd3);
    `check_eq(dut.col_r, 4'd3);
    `check_eq(dut.grant_r, 1'b1);
    `check_eq(read_wb.stall_i, 1'b0);
    `check_eq(read_wb.dat_i, 8'h55);


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

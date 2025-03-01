`timescale 1 ns / 1 ps

module vga_out_tb;

  import vga_pkg::*;
  import logger_pkg::*;

  localparam CLK_PERIOD = 25ns;

  logic clk;
  logic rst;
  int frame_ctr;

  vga_if out_vga();
  vga_if in_vga();

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  assign in_vga.rgb = dut.buffer_select ? 12'hBBB : 12'hAAA; 

// hcount and vcount driver
  always_ff @(posedge clk) begin: hcount_blk
    if(rst) begin
      in_vga.hcount <= 11'b0;
      in_vga.vcount <= 11'b0;
    end
    else if(in_vga.hcount == HCOUNT_MAX) begin
      in_vga.hcount <= 11'b0;
      if (in_vga.vcount == VCOUNT_MAX) begin
        in_vga.vcount <= 11'b0;
      end
      else begin
        in_vga.vcount <= in_vga.vcount + 1;
      end
    end
    else begin
      in_vga.hcount <= in_vga.hcount + 1;
    end
  end

  vga_out dut(
    .clk,
    .rst,
    .in(in_vga.in),
    .out(out_vga.out)
  );

  initial begin
    void'(logger::init());
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    while (frame_ctr < 3) begin
      if(dut.frame_ready) frame_ctr++;
      @(posedge clk);
    end
    foreach (dut.line_buffer_A[i]) `check_eq(dut.line_buffer_A[i], 12'hAAA);
    foreach (dut.line_buffer_B[i]) `check_eq(dut.line_buffer_B[i], 12'hBBB);
    WaitClocks(100);
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

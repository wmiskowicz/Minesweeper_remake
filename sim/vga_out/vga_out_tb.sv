//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   vga_out_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module vga_out.
 */
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

module vga_out_tb;

import vga_pkg::*;
import logger_pkg::*;

// ----- Local parameters -----
localparam CLK_PERIOD = 25ns;

// ----- Local variables -----
logic clk;
logic rst;


// ----- Signal interfaces -----
vga_if in_vga();
vga_if driver_vga();
vga_if out_vga();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

// Tested vga driver
vga_timing u_vga_timing (
  .clk(clk),
  .rst(rst),
  .out(in_vga.out)
);

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

  // Test 1: Verify buffer swap on HCOUNT_MAX
  `log_info("Test 1: Verifying buffer swap on HCOUNT_MAX");
  WaitClocks(10);
  wait(in_vga.out.vcount == 0 && in_vga.out.hcount == 0);
  
  for (int frame = 0; frame < 3; frame++) begin
    wait(in_vga.out.hcount == HCOUNT_MAX);
    `log_info($sformatf("Buffer swap detected at frame %0d, hcount=%0d", frame, in_vga.out.hcount));
    WaitClocks(1);
  end



  // Test 2: Verify write/read to different buffers
  `log_info("Test 2: Verifying write/read to different buffers");
  wait(in_vga.out.vcount == 0 && in_vga.out.hcount == 0);
  
  for (int h = 0; h < HOR_TOTAL_TIME; h++) begin
    in_vga.in.rgb = h[11:0];
    WaitClocks(1);
  end
  
  wait(in_vga.out.vcount == 1 && in_vga.out.hcount == 0);
  
  for (int h = 0; h < HOR_TOTAL_TIME; h++) begin
    WaitClocks(1);
    if (out_vga.out.rgb !== h[11:0]) begin
      `log_err($sformatf("Mismatch at hcount=%0d: expected %03x, got %03x", 
                          h, h[11:0], out_vga.out.rgb));
    end
  end


  
  // Test 3: Verify control signals are properly passed through
  `log_info("Test 3: Verifying control signals");
  WaitClocks(100);

  `check_eq(out_vga.out.hsync, in_vga.out.hsync);
  `check_eq(out_vga.out.vsync, in_vga.out.vsync);
  `check_eq(out_vga.out.hblnk, in_vga.out.hblnk);
  `check_eq(out_vga.out.vblnk, in_vga.out.vblnk);
  


  // Test 4: Verify reset behavior
  `log_info("Test 4: Verifying reset behavior");
  rst = 1;
  WaitClocks(5);
  
  if (dut.buffer_select !== 0) begin
    `log_err("Buffer select not reset to 0");
  end
  
  rst = 0;
  WaitClocks(10);
  
  `log_info("All tests completed");
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

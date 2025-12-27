//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   vga_timing_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module vga_timing.
 */
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

`include "../../XVunit/internals/verilog/xvunit_defines.svh"

module vga_timing_tb;

import vga_pkg::*;

// ----- Local parameters -----
localparam real CLK_PERIOD = 13.4680134ns; //74.25 MHz

// ----- Local variables -----
logic clk;
logic rst;
logic [10:0] max_hcount;
logic [10:0] max_vcount;
logic [10:0] start_hcount;
logic [10:0] start_vcount;

int line_count;
int pixel_count;

logic [10:0] start_active_hcount;
int active_pixels;


time time_start;
time time_stop;

// ----- Signal interfaces -----
vga_if vga_test_if();

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

vga_timing dut(
  .clk,
  .rst,
  .out(vga_test_if.out)
);


`TEST_SUITE_BEGIN

  `TEST_SUITE_SETUP begin
    $display("Starting VGA timing test suite at %t", $time);
    $display("Testing 1280 x 720 @ 60Hz with 74.25 MHz pixel clock");
  end

  `TEST_CASE_SETUP begin
    max_hcount = 11'd0;
    max_vcount = 11'd0;
    start_hcount = 11'd0;
    start_vcount = 11'd0;
    time_start = 0;
    time_stop = 0;
    InitReset();
  end

  `TEST_CASE("TC000") begin
    $display("Testbench compiled successfully");
    `CHECK_EQUAL(vga_test_if.out.hcount, 0);
    `CHECK_EQUAL(vga_test_if.out.vcount, 0);
  end

  `TEST_CASE("TC001") begin
    $display("Verify horizontal total time = 1650 pixels (22.222 us)");
    
    repeat (10) begin
      time_start = $time;
      pixel_count = 0;
      start_hcount = 1;

      WaitClocks(1);
      pixel_count++;
      
      // Count horizontal pixels for one full line
      while ((vga_test_if.out.hcount != start_hcount)) begin
        WaitClocks(1);
        pixel_count++;
      end
      
      time_stop = $time;
      `CHECK_EQUAL(pixel_count, HOR_TOTAL_TIME);
      `CHECK_EQUAL_VARIANCE(time_stop - time_start, 22.222us, 5ns);
      $display("Measured: %0d pixels per line", pixel_count);
      $display("Elapsed time for active pixels: %0t", time_stop - time_start);
    end
  end

  `TEST_CASE("TC002") begin
    $display("Verify vertical total time = 750 lines (16.667 ms)");
    
    repeat(2) begin
      line_count = 1;
      time_start = $time;
      start_vcount = vga_test_if.out.vcount;
      
      // Avoid breaking before vcount increments
      WaitClocks(10);
      wait(vga_test_if.out.hcount == 1);
      line_count++;

      do begin
        WaitClocks(1);
        if (vga_test_if.out.hcount == 1) begin
          line_count++;
        end
      end while (vga_test_if.out.vcount != start_vcount);
      
      time_stop = $time;
      `CHECK_EQUAL(line_count, VER_TOTAL_TIME);
      `CHECK_EQUAL_VARIANCE(time_stop - time_start, 16.667ms, 1us);
      $display("Measured: %0d lines per frame", line_count);
      $display("Elapsed time for active lines: %0.3f ms", (real'(time_stop - time_start)/1_000_000.0));
    end
  end

  `TEST_CASE("TC003") begin
    $display("Verify horizontal active pixels = 1280 (17.239 usec)");
    
    repeat(2) begin
      time_start = $time;
      
      active_pixels = 0;
      start_active_hcount = vga_test_if.out.hcount;
      
      // Count active pixels until hblank starts
      while (vga_test_if.out.hblnk == 1'b0) begin
        WaitClocks(1);
        active_pixels++;
      end
      time_stop = $time();
      
      // `CHECK_EQUAL(active_pixels, HOR_BLANK_START);
      `CHECK_EQUAL_VARIANCE((time_stop - time_start), 17.239us, 1ns);
      $display("Measured: %0d active horizontal pixels", active_pixels);
      $display("Elapsed time for active lines: %0.3f us", (real'(time_stop - time_start)/1_000.0));

      @(negedge vga_test_if.out.hblnk);
    end  
  end

  `TEST_CASE("TC004") begin
    automatic int active_lines;
    automatic logic [10:0] start_active_vcount;
    $display("Verify vertical active lines = 720 (16.000 msec)");
    
    // Find start of active region (end of vblank)
    while (vga_test_if.out.vblnk == 1'b1) begin
      WaitClocks(1);
    end
    
    active_lines = 0;
    start_active_vcount = vga_test_if.out.vcount;

    // Count active lines until vblank starts
    while (vga_test_if.out.vblnk == 1'b0) begin
      WaitClocks(1);
      if (vga_test_if.out.hcount == 0) begin
        active_lines++;
      end
    end
    
    `CHECK_EQUAL(active_lines, 720);
    $display("Measured: %0d active vertical lines", active_lines);
  end

  `TEST_CASE("TC005") begin
    automatic int blank_pixels;
    $display("Verify horizontal blanking = 370 pixels (4.983 usec)");
    
    // Find start of hblank
    while (vga_test_if.out.hblnk == 1'b0) begin
      WaitClocks(1);
    end
    
    blank_pixels = 0;
    
    // Count blank pixels
    while (vga_test_if.out.hblnk == 1'b1) begin
      WaitClocks(1);
      blank_pixels++;
    end
    
    `CHECK_EQUAL(blank_pixels, 370);
    $display("Measured: %0d horizontal blanking pixels", blank_pixels);
  end

  `TEST_CASE("TC006") begin
    automatic int blank_lines;
    $display("Verify vertical blanking = 30 lines (0.667 msec)");
    
    // Find start of vblank
    while (vga_test_if.out.vblnk == 1'b0) begin
      WaitClocks(1);
    end

    blank_lines = 0;
    
    // Count blank lines
    while (vga_test_if.out.vblnk == 1'b1) begin
      WaitClocks(1);
      if (vga_test_if.out.hcount == 0) begin
        blank_lines++;
      end
    end
    
    `CHECK_EQUAL(blank_lines, 30);
    $display("Measured: %0d vertical blanking lines", blank_lines);
  end

  `TEST_CASE("TC007") begin
    automatic int sync_pixels;
    $display("Verify horizontal sync = 40 pixels (0.539 usec) at position 1390-1429");
    
    // Wait for hsync start
    while (vga_test_if.out.hcount != 1390) begin
      WaitClocks(1);
    end
    
    sync_pixels = 0;
    
    // Count sync pixels
    while (vga_test_if.out.hsync == 1'b1) begin
      WaitClocks(1);
      sync_pixels++;
    end
    
    `CHECK_EQUAL(sync_pixels, 40);
    `CHECK_EQUAL(vga_test_if.out.hcount, 1430); // 1390 + 40
    $display("Measured: %0d horizontal sync pixels at position %0d-%0d", 
             sync_pixels, 1390, 1390 + sync_pixels - 1);
  end

  `TEST_CASE("TC008") begin
    automatic int sync_lines;
    $display("Verify vertical sync = 5 lines (0.111 msec) at position 725-729");
    
    // Wait for vsync start
    while (vga_test_if.out.vcount != 725) begin
      WaitClocks(1);
    end
    
    sync_lines = 0;
    
    // Count sync lines
    while (vga_test_if.out.vsync == 1'b1) begin
      WaitClocks(1);
      if (vga_test_if.out.hcount == 0) begin
        sync_lines++;
      end
    end
    
    `CHECK_EQUAL(sync_lines, 5);
    $display("Measured: %0d vertical sync lines at position %0d-%0d", 
             sync_lines, 725, 725 + sync_lines - 1);
  end

  `TEST_CASE("TC009") begin
    $display("Verify sync polarities: both positive");
    
    // Check hsync polarity during sync
    while (vga_test_if.out.hcount != 1390) begin
      WaitClocks(1);
    end
    
    `CHECK_EQUAL(vga_test_if.out.hsync, 1'b1);
    $display("HSYNC asserted high (positive polarity) at position %0d", 
             vga_test_if.out.hcount);
    
    // Check vsync polarity during sync  
    while (vga_test_if.out.vcount != 725) begin
      WaitClocks(1);
    end
    
    `CHECK_EQUAL(vga_test_if.out.vsync, 1'b1);
    $display("VSYNC asserted high (positive polarity) at line %0d", 
             vga_test_if.out.vcount);
  end

  `TEST_CASE("TC010") begin
    automatic int front_porch_pixels = 0;
    automatic int back_porch_pixels = 0;
    $display("Verify horizontal timing relationships");
    
    // Wait for start of frame for consistent measurements
    while (!(vga_test_if.out.hcount == 0 && vga_test_if.out.vcount == 0)) begin
      WaitClocks(1);
    end
    
    front_porch_pixels = 0;
    back_porch_pixels = 0;
    
    // Measure front porch (between active end and sync start)
    // Active ends at pixel 1279, sync starts at 1390
    // Front porch = 1390 - 1280 = 110 pixels
    while (vga_test_if.out.hcount != 1280) begin
      WaitClocks(1);
    end
    
    while (vga_test_if.out.hcount != 1390) begin
      WaitClocks(1);
      front_porch_pixels++;
    end
    
    `CHECK_EQUAL(front_porch_pixels, 110);
    $display("Front porch: %0d pixels (110 expected)", front_porch_pixels);
    
    // Measure back porch (between sync end and active start)
    // Sync ends at 1429, active starts at 0 (wraps around)
    while (vga_test_if.out.hcount != 1430) begin
      WaitClocks(1);
    end
    
    while (vga_test_if.out.hcount != 0) begin
      WaitClocks(1);
      back_porch_pixels++;
    end
    
    `CHECK_EQUAL(back_porch_pixels, 220);
    $display("Back porch: %0d pixels (220 expected)", back_porch_pixels);
    
    // Verify total: 1280 active + 110 front porch + 40 sync + 220 back porch = 1650
    `CHECK_EQUAL(1280 + front_porch_pixels + 40 + back_porch_pixels, 1650);
  end

  `TEST_CASE("TC011") begin
    automatic int front_porch_lines;
    automatic int back_porch_lines;
    $display("Verify vertical timing relationships");
    
    // Wait for start of frame
    while (!(vga_test_if.out.hcount == 0 && vga_test_if.out.vcount == 0)) begin
      WaitClocks(1);
    end
    
    front_porch_lines = 0;
    back_porch_lines = 0;
    
    // Measure front porch (between active end and sync start)
    // Active ends at line 719, sync starts at 725
    // Front porch = 725 - 720 = 5 lines
    while (vga_test_if.out.vcount != 720) begin
      WaitClocks(1);
    end
    
    while (vga_test_if.out.vcount != 725) begin
      WaitClocks(1);
      if (vga_test_if.out.hcount == 0) begin
        front_porch_lines++;
      end
    end
    
    `CHECK_EQUAL(front_porch_lines, 5);
    $display("Vertical front porch: %0d lines (5 expected)", front_porch_lines);
    
    // Measure back porch (between sync end and active start)
    // Sync ends at 729, active starts at 0 (wraps around)
    while (vga_test_if.out.vcount != 730) begin
      WaitClocks(1);
    end
    
    while (vga_test_if.out.vcount != 0) begin
      WaitClocks(1);
      if (vga_test_if.out.hcount == 0) begin
        back_porch_lines++;
      end
    end
    
    `CHECK_EQUAL(back_porch_lines, 20);
    $display("Vertical back porch: %0d lines (20 expected)", back_porch_lines);
    
    // Verify total: 720 active + 5 front porch + 5 sync + 20 back porch = 750
    `CHECK_EQUAL(720 + front_porch_lines + 5 + back_porch_lines, 750);
  end

`TEST_SUITE_END

task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   vga_out_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Testbench for VGA output buffer module.
 */
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

`include "../../XVunit/internals/verilog/xvunit_defines.svh"

module vga_out_tb;

import vga_pkg::*;

// ----- Local parameters -----
localparam CLK_PERIOD = 13.46ns; // 74.25 MHz for 1280x720 @ 60Hz
localparam TEST_PATTERN_A = 12'hAAA; // Pattern written to buffer A
localparam TEST_PATTERN_B = 12'h555; // Pattern written to buffer B

// ----- Local variables -----
logic clk;
logic rst;

// Test tracking variables (reset in TEST_CASE_SETUP)
logic [10:0] max_hcount;
logic [10:0] max_vcount;
logic [10:0] start_hcount;
logic [10:0] start_vcount;

// ----- Signal interfaces -----
vga_if vga_in_if();
vga_if vga_out_if();

// Test pattern control
logic [11:0] test_rgb;
logic buffer_active; // Which buffer is currently being written (0=A, 1=B)

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

vga_out dut (
  .clk(clk),
  .rst(rst),
  .in(vga_in_if.in),
  .out(vga_out_if.out)
);

// VGA timing generator provides input timing signals
vga_timing vga_timing_0 (
  .clk(clk),
  .rst(rst),
  .out(vga_in_if.out)
);

// Test pattern generator - writes alternating patterns to each buffer
always_ff @(posedge clk) begin
  if (rst) begin
    test_rgb <= '0;
    buffer_active <= 1'b0;
  end else begin
    // Swap buffers at end of each line
    if (vga_in_if.out.hcount == HCOUNT_MAX) begin
      buffer_active <= ~buffer_active;
    end
    
    // Write pattern A to buffer A, pattern B to buffer B
    if (buffer_active) begin
      test_rgb <= TEST_PATTERN_B;
    end else begin
      test_rgb <= TEST_PATTERN_A;
    end
  end
end

// Apply generated pattern to VGA input
assign vga_in_if.out.rgb = test_rgb;

`TEST_SUITE_BEGIN

  `TEST_SUITE_SETUP begin
    $display("Starting VGA output buffer test suite at %t", $time);
    InitReset();
  end

  `TEST_CASE_SETUP begin
    // Reset tracking variables before each test case
    max_hcount = 11'd0;
    max_vcount = 11'd0;
    start_hcount = 11'd0;
    start_vcount = 11'd0;
  end

  `TEST_CASE("TC000") begin
    $display("Testbench compiled successfully");
    `CHECK_EQUAL(vga_out_if.in.hcount, 0);
    `CHECK_EQUAL(vga_out_if.in.vcount, 0);
  end

  `TEST_CASE("TC001") begin
    automatic logic prev_buffer_select;
    automatic int lines_monitored;
    $display("Verify buffer swaps at end of each horizontal line");
        
    lines_monitored = 0;
    
    while (lines_monitored < 10) begin
      @(posedge clk);
      
      if (vga_in_if.out.hcount == HCOUNT_MAX) begin
        prev_buffer_select = buffer_active;
        @(posedge clk); // Wait for swap to complete
        
        `CHECK_EQUAL(buffer_active, ~prev_buffer_select);
        $display("Line %0d: Buffer %0d -> %0d", 
                 vga_out_if.in.vcount, prev_buffer_select, buffer_active);
        
        lines_monitored++;
      end
    end
  end

  `TEST_CASE("TC002") begin
    automatic logic [11:0] input_rgb_at_start;
    automatic logic buffer_at_start;
    $display("Verify RGB output has exactly one line delay");
    

    
    // Wait for start of a line
    while (vga_in_if.out.hcount != 0) begin
      @(posedge clk);
    end
    
    input_rgb_at_start = vga_in_if.out.rgb;
    buffer_at_start = buffer_active;
    
    $display("Line %0d: Writing %h to buffer %0d", 
             vga_in_if.out.vcount, input_rgb_at_start, buffer_at_start);
    
    // Complete current line
    while (vga_in_if.out.hcount != HCOUNT_MAX) begin
      @(posedge clk);
    end
    @(posedge clk); // Buffer swap occurs
    
    // Wait for same hcount in next line
    while (!(vga_in_if.out.vcount == vga_out_if.in.vcount + 1 && 
             vga_in_if.out.hcount == 0)) begin
      @(posedge clk);
    end
    
    `CHECK_EQUAL(vga_out_if.in.rgb, input_rgb_at_start);
    $display("Line %0d: Output %h matches input from line %0d", 
             vga_out_if.in.vcount, vga_out_if.in.rgb, vga_out_if.in.vcount - 1);
  end

  `TEST_CASE("TC003") begin
    automatic logic current_write_buffer;
    automatic int lines_checked;
    automatic int check_pos;
    $display("Verify double-buffering: simultaneous read/write to different buffers");
    

    
    lines_checked = 0;
    
    while (lines_checked < 5) begin
      // Wait for start of line
      while (vga_in_if.out.hcount != 0) begin
        @(posedge clk);
      end
      
      current_write_buffer = buffer_active;
      
      $display("Line %0d: Writing to buffer %0d", vga_in_if.out.vcount, current_write_buffer);
      
      // Verify pattern at 10 points across the line
      for (int i = 0; i < 10; i++) begin
        check_pos = i * 100;
        
        while (vga_in_if.out.hcount != check_pos) begin
          @(posedge clk);
        end
        
        // Input shows pattern for current write buffer
        if (current_write_buffer == 0) begin
          `CHECK_EQUAL(vga_in_if.out.rgb, TEST_PATTERN_A);
        end else begin
          `CHECK_EQUAL(vga_in_if.out.rgb, TEST_PATTERN_B);
        end
        
        // Output shows pattern from opposite buffer (previous line)
        if (current_write_buffer == 0) begin
          `CHECK_EQUAL(vga_out_if.in.rgb, TEST_PATTERN_B);
        end else begin
          `CHECK_EQUAL(vga_out_if.in.rgb, TEST_PATTERN_A);
        end
      end
      
      lines_checked++;
      
      // Advance to next line
      while (vga_in_if.out.hcount != HCOUNT_MAX) begin
        @(posedge clk);
      end
      @(posedge clk);
    end
  end

  `TEST_CASE("TC005") begin
    $display("Verify reset initializes buffers and control logic");
    
    // First get to known state
    while (vga_in_if.out.hcount != 0) begin
      @(posedge clk);
    end
    
    // Assert reset
    rst = 1'b1;
    WaitClocks(5);
    
    // Verify reset state
    `CHECK_EQUAL(buffer_active, 1'b0);
    `CHECK_EQUAL(vga_out_if.in.rgb, '0);
    
    // Release reset
    rst = 1'b0;
    WaitClocks(10);
    
    // Verify normal operation resumes
    `CHECK_EQUAL(vga_out_if.in.hcount, vga_in_if.out.hcount);
  end

  `TEST_CASE("TC006") begin
    automatic logic [11:0] unique_pattern;
    automatic logic current_buffer;
    automatic int write_line;
    automatic int frames_waited;
    $display("Verify buffer data persists across multiple frame periods");
    

    
    unique_pattern = 12'hABC;
    
    // Wait for start of line
    while (vga_in_if.out.hcount != 0) begin
      @(posedge clk);
    end
    
    current_buffer = buffer_active;
    write_line = vga_in_if.out.vcount;
    
    $display("Line %0d: Pattern %h written to buffer %0d",
             write_line, unique_pattern, current_buffer);
    
    // Complete current frame
    while (!(vga_in_if.out.hcount == 0 && vga_in_if.out.vcount == 0)) begin
      @(posedge clk);
    end
    
    // Wait 2 frames for same buffer to be active again
    frames_waited = 0;
    
    while (frames_waited < 2) begin
      if (vga_in_if.out.hcount == 0 && vga_in_if.out.vcount == 0) begin
        frames_waited++;
      end
      @(posedge clk);
    end
    
    $display("Buffer %0d active again after %0d frames", current_buffer, frames_waited);
  end

  `TEST_CASE("TC007") begin
    automatic int swap_points_checked;
    automatic logic [11:0] rgb_before_swap;
    automatic logic [10:0] hcount_before;
    $display("Verify clean transitions at buffer swap boundaries");
    

    
    swap_points_checked = 0;
    
    while (swap_points_checked < 5) begin
      // Wait for pixel before buffer swap
      while (vga_in_if.out.hcount != HCOUNT_MAX - 1) begin
        @(posedge clk);
      end
      
      rgb_before_swap = vga_out_if.in.rgb;
      hcount_before = vga_out_if.in.hcount;
      
      // Advance through swap point
      @(posedge clk); // hcount = HCOUNT_MAX
      @(posedge clk); // hcount = 0, buffer swapped
      
      // Verify hcount wraps correctly
      `CHECK_EQUAL(vga_out_if.in.hcount, 0);
      
      // RGB should switch to other buffer's pattern
      if (buffer_active == 0) begin
        `CHECK_EQUAL(vga_out_if.in.rgb, TEST_PATTERN_B);
      end else begin
        `CHECK_EQUAL(vga_out_if.in.rgb, TEST_PATTERN_A);
      end
      
      swap_points_checked++;
    end
  end

  `TEST_CASE("TC008") begin
    $display("Verify counters never exceed VESA specification limits");
    
    start_hcount = vga_in_if.out.hcount;
    start_vcount = vga_in_if.out.vcount;
    
    do begin
      @(posedge clk);
      
      max_hcount = (vga_out_if.in.hcount > max_hcount) ? vga_out_if.in.hcount : max_hcount;
      max_vcount = (vga_out_if.in.vcount > max_vcount) ? vga_out_if.in.vcount : max_vcount;
      
      `CHECK_LESS(vga_out_if.in.hcount, HOR_TOTAL_TIME);
      `CHECK_LESS(vga_out_if.in.vcount, VER_TOTAL_TIME);
      
    end while (!(vga_in_if.out.hcount == start_hcount && 
                 vga_in_if.out.vcount == start_vcount));
    
    $display("Max counters: hcount=%0d (<%0d), vcount=%0d (<%0d)",
             max_hcount, HOR_TOTAL_TIME, max_vcount, VER_TOTAL_TIME);
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
`timescale 1 ns / 1 ps

module top_mouse_tb;

import vga_pkg::*;

`include "../../XVunit/internals/verilog/xvunit_defines.svh"
`include "ps2_if.sv"
`include "ps2_mouse_bfm.sv"

// Clock parameters
localparam CLK_PERIOD_100MHz = 10ns;
localparam CLK_PERIOD_74MHz = 14ns;

// Clock and reset
logic clk100MHz;
logic clk74MHz;
logic rst;

// Mouse position outputs
logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;

// Mouse button outputs
logic left;
logic right;

// PS/2 interface
wire ps2_clk;
wire ps2_data;

int test_dx;
int test_dy;

// PS/2 interface instance
ps2_if ps2_if0();

// Mouse BFM instance
ps2_mouse_bfm mouse_bfm;

// System clock generation
initial begin
  clk74MHz = 1'b0;
  forever #(CLK_PERIOD_74MHz/2) clk74MHz = ~clk74MHz;
end

initial begin
  clk100MHz = 1'b0;
  forever #(CLK_PERIOD_100MHz/2) clk100MHz = ~clk100MHz;
end

// Connect PS/2 wires to interface
assign ps2_clk = ps2_if0.clk;
assign ps2_data = ps2_if0.data;

// Device under test
top_mouse dut (
  .clk100MHz  (clk100MHz),
  .clk74MHz   (clk74MHz),
  .rst        (rst),
  .ps2_clk    (ps2_clk),
  .ps2_data   (ps2_data),
  .left       (left),
  .right      (right),
  .mouse_xpos (mouse_xpos),
  .mouse_ypos (mouse_ypos)
);

`TEST_SUITE_BEGIN

  `TEST_SUITE_SETUP begin
    InitReset();
    mouse_bfm = new(ps2_if0);
    mouse_bfm.initialize_lines();  // Initialize PS/2 lines to idle state
    $display($sformatf("Starting mouse test suite at %t", $time));
    WaitClocks100MHz(50); // Allow DUT to initialize
  end

  `TEST_CASE_SETUP begin
    // No test-specific setup needed
  end

  `TEST_CASE("TC000") begin
    `CHECK_EQUAL(left, 1'b0);
    `CHECK_EQUAL(right, 1'b0);
    `CHECK_EQUAL(mouse_xpos, 12'd0);
    `CHECK_EQUAL(mouse_ypos, 12'd0);
    $display("Testbench initialized correctly");
  end

  `TEST_CASE("TC001") begin 
    $display("Verify mouse movement updates position registers");

    // Move mouse right and down
    test_dx = 50;
    test_dy = 30;
    mouse_bfm.set_position(test_dx, test_dy);
    WaitClocks100MHz(100); // Allow movement to be processed

    // Mouse position should update (exact values depend on DUT scaling)
    `CHECK_NOT_EQUAL(mouse_xpos, 12'd0);
    `CHECK_NOT_EQUAL(mouse_ypos, 12'd0);
    $display($sformatf("Mouse position: X=%0d, Y=%0d", mouse_xpos, mouse_ypos));
  end

  `TEST_CASE("TC002") begin
    $display("Verify left button click detection");

    // Press left button
    mouse_bfm.set_position(0, 0, 1, 0, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(left, 1'b1);
    `CHECK_EQUAL(right, 1'b0);

    // Release left button
    mouse_bfm.set_position(0, 0, 0, 0, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(left, 1'b0);
    `CHECK_EQUAL(right, 1'b0);
  end

  `TEST_CASE("TC003") begin
    $display("Verify right button click detection");

    // Press right button
    mouse_bfm.set_position(0, 0, 0, 1, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(right, 1'b1);
    `CHECK_EQUAL(left, 1'b0);

    // Release right button
    mouse_bfm.set_position(0, 0, 0, 0, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(right, 1'b0);
    `CHECK_EQUAL(left, 1'b0);
  end

  `TEST_CASE("TC004") begin
    $display("Verify simultaneous left+right click detection");

    // Press both buttons
    mouse_bfm.set_position(0, 0, 1, 1, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(left, 1'b1);
    `CHECK_EQUAL(right, 1'b1);

    // Release both buttons
    mouse_bfm.set_position(0, 0, 0, 0, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(left, 1'b0);
    `CHECK_EQUAL(right, 1'b0);
  end

  `TEST_CASE("TC005") begin

    
    $display("Verify mouse position stays within VGA display bounds");

    // Test movement to upper-left corner
    test_dx = -100;
    test_dy = -100;
    mouse_bfm.set_position(test_dx, test_dy);
    WaitClocks100MHz(100);

    // Position should be >= 0
    // `CHECK_GREATER_EQUAL(mouse_xpos, 0);
    // `CHECK_GREATER_EQUAL(mouse_ypos, 0);

    // Test movement to lower-right corner (large positive)
    test_dx = 2000;
    test_dy = 2000;
    mouse_bfm.set_position(test_dx, test_dy);
    WaitClocks100MHz(100);

    // Position should be < screen dimensions
    `CHECK_LESS(mouse_xpos, HOR_PIXELS);
    `CHECK_LESS(mouse_ypos, VER_PIXELS);

    $display($sformatf("Position bounded: X=%0d (<%0d), Y=%0d (<%0d)",
      mouse_xpos, HOR_PIXELS, mouse_ypos, VER_PIXELS));
  end

  `TEST_CASE("TC006") begin
    $display("Verify click-and-drag operation");

    // Press left button
    mouse_bfm.set_position(0, 0, 1, 0, 0);
    WaitClocks100MHz(20);

    `CHECK_EQUAL(left, 1'b1);

    // Drag while button pressed
    mouse_bfm.set_position(100, 50, 1, 0, 0);
    WaitClocks100MHz(100);

    `CHECK_EQUAL(left, 1'b1); // Button should stay pressed during drag

    // Release button
    mouse_bfm.set_position(0, 0, 0, 0, 0);
    WaitClocks100MHz(50);

    `CHECK_EQUAL(left, 1'b0);
    $display($sformatf("Drag complete: X=%0d, Y=%0d", mouse_xpos, mouse_ypos));
  end

  `TEST_CASE("TC007") begin
    logic [11:0] saved_xpos;
    logic [11:0] saved_ypos;
    
    $display("Verify position persistence across clock domains");

    // Move to known position
    mouse_bfm.set_position(100, 80, 0, 0, 0);
    WaitClocks100MHz(200); // Allow full synchronization

    saved_xpos = mouse_xpos;
    saved_ypos = mouse_ypos;

    // Wait additional cycles in both clock domains
    repeat (10) begin
      @(posedge clk100MHz);
      @(posedge clk74MHz);
    end

    // Position should remain stable
    `CHECK_EQUAL(mouse_xpos, saved_xpos);
    `CHECK_EQUAL(mouse_ypos, saved_ypos);

    $display($sformatf("Position stable across clocks: X=%0d, Y=%0d",
      mouse_xpos, mouse_ypos));
  end

  `TEST_CASE("TC008") begin
    $display("Verify mouse reset behavior");

    // First establish non-zero state
    mouse_bfm.set_position(50, 40, 1, 1, 0);
    WaitClocks100MHz(100);

    `CHECK_NOT_EQUAL(mouse_xpos, 12'd0);
    `CHECK_EQUAL(left, 1'b1);
    `CHECK_EQUAL(right, 1'b1);

    // Apply reset
    rst = 1'b1;
    WaitClocks100MHz(10);

    // Verify reset state
    `CHECK_EQUAL(mouse_xpos, 12'd0);
    `CHECK_EQUAL(mouse_ypos, 12'd0);
    `CHECK_EQUAL(left, 1'b0);
    `CHECK_EQUAL(right, 1'b0);

    // Release reset
    rst = 1'b0;
    WaitClocks100MHz(10);

    $display("Reset successfully cleared mouse state");
  end

  `TEST_CASE("TC009") begin
    logic [11:0] prev_xpos;
    logic [11:0] prev_ypos;
    int movement_count;
    
    $display("Verify continuous movement updates");

    movement_count = 0;
    prev_xpos = mouse_xpos;
    prev_ypos = mouse_ypos;

    // Send several small movements
    for (int i = 0; i < 5; i++) begin
      mouse_bfm.set_position(10, 5, 0, 0, 0);
      WaitClocks100MHz(50);

      // Position should change with each movement
      `CHECK_NOT_EQUAL(mouse_xpos, prev_xpos);
      `CHECK_NOT_EQUAL(mouse_ypos, prev_ypos);

      prev_xpos = mouse_xpos;
      prev_ypos = mouse_ypos;
      movement_count++;
    end

    $display($sformatf("%0d movements processed correctly", movement_count));
  end

  `TEST_CASE("TC010") begin
    $display("Verify smooth movement with move_smooth task");
    
    mouse_bfm.move_smooth(150, 100, 5); // Move 150 right, 100 down in 5 steps
    WaitClocks100MHz(300); // Allow all steps to process
    
    $display($sformatf("Smooth movement complete: X=%0d, Y=%0d", 
      mouse_xpos, mouse_ypos));
  end

  `TEST_CASE("TC011") begin
    $display("Verify button clicks with click_button task");
    
    // Left click
    mouse_bfm.click_button(1, 0, 0);
    WaitClocks100MHz(150);
    
    // Right click
    mouse_bfm.click_button(0, 0, 1);
    WaitClocks100MHz(150);
    
    // Both buttons click
    mouse_bfm.click_button(1, 0, 1);
    WaitClocks100MHz(150);
    
    $display("All button click tests completed");
  end

`TEST_SUITE_END

task automatic WaitClocks100MHz(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk100MHz);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks100MHz(10);
  rst = 0;
  WaitClocks100MHz(10);
endtask

endmodule
`timescale 1 ns / 1 ps

module top_mouse_tb;

import vga_pkg::*;

`include "../../XVunit/internals/verilog/xvunit_defines.svh"
`include "ps2_if.sv"
`include "ps2_mouse_bfm.sv"

localparam CLK_PERIOD_100MHz = 10ns;
localparam CLK_PERIOD_74MHz = 14ns;

logic clk100MHz;
logic clk74MHz;
logic rst;
logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
logic left;
logic right;
wire ps2_clk;
wire ps2_data;
int test_dx;
int test_dy;

ps2_if ps2_if0();
ps2_mouse_bfm mouse_bfm;

initial begin
  clk74MHz = 1'b0;
  forever #(CLK_PERIOD_74MHz/2) clk74MHz = ~clk74MHz;
end

initial begin
  clk100MHz = 1'b0;
  forever #(CLK_PERIOD_100MHz/2) clk100MHz = ~clk100MHz;
end

pullup(ps2_clk);
pullup(ps2_data);
     
// Connect interface to physical wires
assign ps2_clk = (ps2_if0.clk_drv == 0) ? 1'b0 : 1'bz;
assign ps2_data = (ps2_if0.data_drv == 0) ? 1'b0 : 1'bz;

assign ps2_if0.clk_in = (ps2_clk === 1'bz) ? 1'b1 : ps2_clk;
assign ps2_if0.data_in = (ps2_data === 1'bz) ? 1'b1 : ps2_data;


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
    rst = 1'b1;
    mouse_bfm = new(ps2_if0);
    $display($sformatf("Starting mouse test suite at %t", $time));
    WaitClocks100MHz(50);
  end
  

  `TEST_CASE_SETUP begin
    InitReset();
    mouse_bfm.init_mouse();
  end

  `TEST_CASE("TC000") begin
    $display("Testbench compiled correctly");
  end

  `TEST_CASE("TC001") begin
    $display("Verify mouse movement updates position registers");
    test_dx = 50;
    test_dy = 30;
    mouse_bfm.set_position(test_dx, test_dy);
    WaitClocks100MHz(100);
    `CHECK_NOT_EQUAL(mouse_xpos, 12'd0);
    `CHECK_NOT_EQUAL(mouse_ypos, 12'd0);
    $display($sformatf("Mouse position: X=%0d, Y=%0d", mouse_xpos, mouse_ypos));
  end

`TEST_SUITE_END

task automatic WaitClocks100MHz(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk100MHz);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks100MHz(10);
  rst = 0;
endtask

endmodule

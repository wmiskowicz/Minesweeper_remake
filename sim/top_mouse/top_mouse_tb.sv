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
bit left_seen;
bit right_seen;

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

// ----- PS/2 open-drain bus model -----
// On the board each line has a pull-up and both ends can only pull it
// low. A Verilog pullup() reaches the VHDL Ps2Interface as the weak
// value 'H', and Ps2Interface compares its inputs against the literal
// '1' (e.g. "if ps2_clk_s = '1'"), which never matches 'H' - the host
// FSM then stalls forever in tx_wait_up_edge. On the FPGA the input
// buffer converts the pulled-up pad to a clean '1', so we model that
// here: when nobody pulls a line low, the testbench drives a strong
// '1'. When the DUT pulls low, the testbench lets go ('z') so its '0'
// wins without contention. The DUT's open-drain enables are internal
// to the VHDL, hence the hierarchical references.
wire dut_clk_low  = (dut.u_MouseCtl.Inst_Ps2Interface.ps2_clk_h  === 1'b0);
wire dut_data_low = (dut.u_MouseCtl.Inst_Ps2Interface.ps2_data_h === 1'b0);

assign ps2_clk  = (ps2_if0.clk_drv  === 1'b0) ? 1'b0 : (dut_clk_low  ? 1'bz : 1'b1);
assign ps2_data = (ps2_if0.data_drv === 1'b0) ? 1'b0 : (dut_data_low ? 1'bz : 1'b1);

assign ps2_if0.clk_in  = (ps2_clk  === 1'b0) ? 1'b0 : 1'b1;
assign ps2_if0.data_in = (ps2_data === 1'b0) ? 1'b0 : 1'b1;


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
    // A real mouse clocks at 60-100us per bit; that makes the DUT's
    // ~11-command init sequence take ~20ms of simulated time, far too
    // slow for xsim. Ps2Interface has no upper bound on the bit rate
    // (it only debounces for ~150ns and waits 63 cycles after releasing
    // the clock), so run the BFM at 2us per bit.
    mouse_bfm = new(ps2_if0, 1us);
    mouse_bfm.start();
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
    // DUT reports xpos directly (x_sign is used as received) but
    // inverts the y axis to move the screen origin to the top-left
    // corner, so a negative dy from the mouse increases mouse_ypos.
    $display("Verify mouse movement updates position registers");
    test_dx = 50;
    test_dy = -30;
    mouse_bfm.set_position(test_dx, test_dy);
    WaitClocks100MHz(200);
    `CHECK_EQUAL(mouse_xpos, 12'd50);
    `CHECK_EQUAL(mouse_ypos, 12'd30);
    $display($sformatf("Mouse position: X=%0d, Y=%0d", mouse_xpos, mouse_ypos));
  end

  `TEST_CASE("TC002") begin
    $display("Verify left and right clicks produce a pulse on left/right outputs");

    left_seen = 1'b0;
    fork
      begin
        forever begin
          @(posedge clk74MHz);
          if (left) left_seen = 1'b1;
        end
      end
      mouse_bfm.click_button(1, 0, 0);
    join_any
    disable fork;
    `CHECK_EQUAL(left_seen, 1'b1);

    right_seen = 1'b0;
    fork
      begin
        forever begin
          @(posedge clk74MHz);
          if (right) right_seen = 1'b1;
        end
      end
      mouse_bfm.click_button(0, 0, 1);
    join_any
    disable fork;
    `CHECK_EQUAL(right_seen, 1'b1);
  end

  `TEST_CASE("TC003") begin
    $display("Verify mouse position saturates at the configured maximum");
    for (int i = 0; i < 15; i++) begin
      mouse_bfm.set_position(127, 0);
    end
    WaitClocks100MHz(200);
    `CHECK_EQUAL(mouse_xpos, 12'd1279);
    $display($sformatf("Mouse position after overrun: X=%0d", mouse_xpos));
  end

`TEST_SUITE_END

// Safety net. XVunit's WATCHDOG only reports an $error and lets the
// free-running clocks keep the simulation alive forever, so also stop
// the simulator hard a little later. The limit covers the whole suite:
// every test case re-runs the DUT's mouse init (11 host commands plus
// 13 response bytes, ~2.5ms with the BFM clock used below).
`WATCHDOG(30ms)

initial begin
  #31ms;
  $fatal(1, "Hard timeout: simulation did not finish - PS/2 handshake stuck?");
end

task automatic WaitClocks100MHz(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk100MHz);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks100MHz(10);
  rst = 0;
endtask

endmodule

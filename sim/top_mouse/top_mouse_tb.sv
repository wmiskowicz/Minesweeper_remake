`timescale 1 ns / 1 ps

module top_mouse_tb;

  import vga_pkg::*;
  import logger_pkg::*;

  localparam CLK_PERIOD_100MHz = 10ns;
  localparam CLK_PERIOD_74MHz = 14ns;

  logic clk100MHz;
  logic clk74MHz;
  logic rst;

  logic [11:0] mouse_xpos;
  logic [11:0] mouse_ypos;
  logic [11:0] xpos_in;
  logic [11:0] ypos_in;
  logic [11:0] xpos_out;
  logic [11:0] ypos_out;

  initial begin
    clk74MHz = 1'b0;
    forever #(CLK_PERIOD_74MHz/2) clk74MHz = ~clk74MHz;
  end

  initial begin
    clk100MHz = 1'b0;
    forever #(CLK_PERIOD_100MHz/2) clk100MHz = ~clk100MHz;
  end
  
  initial begin
    xpos_in = '0;
    ypos_in = '0;
    forever begin 
      xpos_in <= xpos_in + 1;
      ypos_in <= ypos_in + 1;
      WaitClocks100MHz(1);
    end
  end




top_mouse dut (
  .clk100MHz (clk100MHz),
  .clk74MHz  (clk74MHz),
  .rst       (rst),
  .ps2_clk   (PS2Clk),
  .ps2_data  (PS2Data),

  .left      (left),
  .right     (right),
  .mouse_xpos(mouse_xpos),
  .mouse_ypos(mouse_ypos)
);

  initial begin
    void'(logger::init());
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));

    click_mouse(20);
    force_xpos_ypos(12'hA5A, 12'h5A5);
    WaitClocks100MHz(100);

    click_mouse(10);
    force_xpos_ypos(12'hAAA, 12'hBBB);
    WaitClocks100MHz(100);

    click_mouse(200);
    force_xpos_ypos(12'hEEE, 12'hFFF);
    WaitClocks100MHz(100);


    $finish;  
  end

  task automatic WaitClocks100MHz(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk100MHz);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks100MHz(10);
    rst = 0;
  endtask

  task automatic click_mouse(input int for_cycles);
    begin
      force dut.left_in  = 1;
      force dut.right_in = 1;
      WaitClocks100MHz(for_cycles);
      `check_eq(dut.left_in, 1'b1);
      force dut.left_in  = 0;
      force dut.right_in = 0;
    end
  endtask

  function force_xpos_ypos(input logic [11:0] xpos, input logic [11:0] ypos);
    begin
      force dut.xpos_in = xpos;
      force dut.ypos_in = ypos;     
    end
  endfunction

endmodule

`timescale 1 ns / 1 ps

module cross_buffer_tb;

  import vga_pkg::*;
  import logger_pkg::*;

  localparam CLK_PERIOD_100MHz = 10ns;
  localparam CLK_PERIOD_74MHz = 14ns;

  logic clk100MHz;
  logic clk74MHz;
  logic rst;

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
      WaitClocks(1);
    end
  end




  cross_buffer u_cross_buffer (
    .clk100MHz(clk100MHz),
    .rst      (rst),
    .slow_clk (clk74MHz),
    .xpos_in  (xpos_in),
    .xpos_out (xpos_out),
    .ypos_in  (ypos_in),
    .ypos_out (ypos_out)
  );

  initial begin
    void'(logger::init());
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));

    
    WaitClocks(100);
    $finish;
  end

    task automatic WaitClocks(input int num_of_clock_cycles);
      repeat (num_of_clock_cycles) @(posedge clk100MHz);
    endtask

    task automatic InitReset();
      rst = 1;
      WaitClocks(10);
      rst = 0;
    endtask

endmodule

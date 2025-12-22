//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Timer testbench
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for timer module.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../XVunit/internals/verilog/xvunit_defines.svh"


module timer_tb;

// ----- Local parameters -----
localparam real CLK_PERIOD = 13.46ns;

// ----- Local variables -----
logic clk;
logic rst;

logic retry;
logic start;
logic stop;
logic [7:0] sec_to_count;

wire time_elapsed;
wire [7:0] sec_left;
wire [7:0] ms_left;

time start_t, stop_t;


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end


top_timer #(
  .F_CLK_HZ(74_250_000)
)
DUT (
  .clk    (clk),
  .rst    (rst),
  .start  (start),
  .stop   (stop),
  .retry  (retry),

  .sec_to_count    (sec_to_count),
  .seconds_left    (sec_left),
  .miliseconds_left(ms_left),
  .time_elapsed    (time_elapsed)
);

    
`TEST_SUITE_BEGIN

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
    end

    `TEST_CASE_SETUP begin
      retry = 1'b0;
      start = 1'b0;
      stop  = 1'b0;
      InitReset();
    end

    `TEST_CASE("TC000") begin
      $display("Testbench compiled succesfully");
    end

    `TEST_CASE("TC001") begin
      automatic logic [7:0] ms_cashed;
      $display("Verify that miliseconds_left output decreases each 10ms +-10us");

      `CHECK_EQUAL(ms_left[3:0], 9);
      `CHECK_EQUAL(ms_left[7:4], 9); 
      start = 1'b1;
      sec_to_count = 5;
      start_t = $time;
      ms_cashed = ms_left;

      for(int i=0; i<99; i++) begin
        wait(ms_left != ms_cashed) stop_t = $time;
        `CHECK_EQUAL_VARIANCE(stop_t-start_t, 10ms, 10us, $sformatf("Failed for i = %d", i));
        WaitClocks(1);

        start_t = stop_t;
        ms_cashed = ms_left;
      end
    end

    `TEST_CASE("TC002") begin 
      $display("Verify that sec_to_count * 1 second time elapses a time_elapsed output is being asserted");
      sec_to_count = 2;
      start = 1'b1;
      start_t = $time;
      @(posedge time_elapsed) stop_t = $time();

      `CHECK_EQUAL_VARIANCE(stop_t-start_t, 2s, 2ms);
    end

    `TEST_CASE("TC003") begin 
      $display("Verify that ms_left is not decrementing when stop input is asserted");

      `CHECK_EQUAL(ms_left[3:0], 9);
      `CHECK_EQUAL(ms_left[7:4], 9); 
      start = 1'b1;
      sec_to_count = 5;
      stop = 1'b1;

      repeat(50) begin
        #1ms;
        `CHECK_EQUAL(ms_left[3:0], 9);
        `CHECK_EQUAL(ms_left[7:4], 9); 
      end
    end

    `TEST_CASE("TC004") begin 
      $display("Verify that after assertion of retry input, timer will not start until the start input is asserted");
      sec_to_count = 2;
      start = 1'b1;
      WaitClocks(10);
      
      start = 1'b0;

      #10ms;
      retry = 1'b1;
      WaitClocks(10);
      retry = 1'b0;
      `CHECK_EQUAL(ms_left[3:0], 9);
      `CHECK_EQUAL(ms_left[7:4], 9);

      #10ms;
      `CHECK_EQUAL(ms_left[3:0], 9);
      `CHECK_EQUAL(ms_left[7:4], 9);
      start = 1'b1;

      #11ms;
      `CHECK_EQUAL(ms_left[3:0], 8);
      `CHECK_EQUAL(ms_left[7:4], 9);
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

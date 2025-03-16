module example_tb;

  import logger_pkg::*;

  logic clk;
  logic rst;
  wishbone_if wb_master();

  localparam CLK_PERIOD = 25ns;

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // DUT instantiation (preserved)
  example dut (
    .clk(clk),
    .rst(rst),
    .wb_master(wb_master)
  );
  string testcase;
  // ----------------------------------------------------------------------------
  // Test Execution
  // ----------------------------------------------------------------------------
  initial begin
    void'(logger::init());
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));


    if (!$value$plusargs("TESTNAME=%s", testcase)) begin
      testcase = "DEFAULT"; // If no test case is specified, run default
    end

    RunTest(testcase);
    $finish;
  end

  // ----------------------------------------------------------------------------
  // Test Case Selection
  // ----------------------------------------------------------------------------
  task automatic RunTest(string test_case);
    case (test_case)
      "TC01": begin
        `log_info("Running TC01");
        RunTC01();
      end
      "TC02": begin
        `log_info("Running TC02");
        RunTC02();
      end
      "TC03": begin
        `log_info("Running TC03");
        RunTC03();
      end
      default: begin
        `log_info("No matching test case found. Running DefaultTest.");
        DefaultTest();
      end
    endcase
  endtask

  // ----------------------------------------------------------------------------
  // Individual Test Cases
  // ----------------------------------------------------------------------------
  task automatic RunTC01();
    `log_info("Executing TC01...");
    // Your test logic here
    WaitClocks(5);
  endtask

  task automatic RunTC02();
    `log_info("Executing TC02...");
    // Your test logic here
    WaitClocks(10);
  endtask

  task automatic RunTC03();
    `log_info("Executing TC03...");
    // Your test logic here
    WaitClocks(15);
  endtask

  task automatic DefaultTest();
    `log_info("Running Default Test...");
    // Default test logic here
    WaitClocks(5);
  endtask

  // ----------------------------------------------------------------------------
  // Utility Functions (Clock Wait & Reset)
  // ----------------------------------------------------------------------------
  task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
  endtask

endmodule

/**
 *  Copyright (C) 2023  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for vga_timing module.
 */

`timescale 1 ns / 1 ps


module vga_timing_tb;

import vga_pkg::*;
import logger_pkg::*;


/**
 *  Local parameters
 */

localparam CLK_PERIOD = 25ns;     // 40 MHz


/**
 * Local variables and signals
 */

logic clk;
logic rst;

vga_if vga_test_if();



/**
 * Clock generation
 */

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end


/**
 * Dut placement
 */

vga_timing dut(
    .clk,
    .rst,
    .out(vga_test_if.out)
);


/**
 * Main test
 */

initial begin
    void'(logger::init());
    InitReset();
    `log_info("Starting test");
    `check_eq(1, 2);
    WaitClocks(50);
    `log_info($sformatf("hcount = %d", vga_test_if.hcount));
    WaitClocks(50);
    // @(negedge vga_test_if.vsync)
    // @(negedge vga_test_if.vsync)

    $finish;
end


/**
 * Tasks and functions
 */

task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
endtask

// Task: Initialize Reset Sequence
task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
    WaitClocks(10); 
endtask


endmodule

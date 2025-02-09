`timescale 1 ns / 1 ps

module vga_timing_tb;

import vga_pkg::*;
import logger_pkg::*;

localparam CLK_PERIOD = 25ns;

logic clk;
logic rst;
logic [10:0] max_hcount, max_vcount;
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

initial begin
    void'(logger::init());
    max_hcount = '0;
    max_vcount = '0;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    WaitClocks(100);
    while (!(vga_test_if.out.vcount == 0 && vga_test_if.out.hcount == 0)) begin
        @(posedge clk) begin
            if (!rst) begin
                // if (vga_test_if.out.hcount >= HSYNC_START && vga_test_if.out.hcount <= HSYNC_STOP) begin
                //     `check_eq(vga_test_if.out.hsync, 1'b1);
                // end
                // else begin
                //     `check_eq(vga_test_if.out.hsync, 1'b0);
                // end
    
                // if (vga_test_if.out.hcount >= HBLNK_START_FRONT && vga_test_if.out.hcount <= HBLNK_STOP_FRONT) begin
                //     `check_eq(vga_test_if.out.hblnk, 1'b1);
                // end
                // else if (vga_test_if.out.hcount >= HBLNK_START_BACK && vga_test_if.out.hcount <= HBLNK_STOP_BACK) begin
                //     `check_eq(vga_test_if.out.hblnk, 1'b1);
                // end
                // else begin
                //     `check_eq(vga_test_if.out.hblnk, 1'b0);
                // end
    
                // if (vga_test_if.out.vcount >= VSYNC_START && vga_test_if.out.vcount <= VSYNC_STOP) begin
                //     `check_eq(vga_test_if.out.vsync, 1'b1);
                // end 
                // else begin
                //     `check_eq(vga_test_if.out.vsync, 1'b0);
                // end
    
                // if (vga_test_if.out.vcount >= VBLNK_START_FRONT && vga_test_if.out.vcount <= VBLNK_STOP_FRONT) begin
                //     `check_eq(vga_test_if.out.vblnk, 1'b1);
                // end
                // else if (vga_test_if.out.vcount >= VBLNK_START_BACK && vga_test_if.out.vcount <= VBLNK_STOP_BACK) begin
                //     `check_eq(vga_test_if.out.vblnk, 1'b1);
                // end
                // else begin
                //     `check_eq(vga_test_if.out.vblnk, 1'b0);
                // end
                `check_eq(vga_test_if.out.rgb, '0);
            end
            max_hcount <= vga_test_if.out.hcount > max_hcount ? vga_test_if.out.hcount : max_hcount;
            max_vcount <= vga_test_if.out.vcount > max_vcount ? vga_test_if.out.vcount : max_vcount;
        end
    end
    `log_info($sformatf("Max hcount = %0d, Max vcount = %0d", max_hcount, max_vcount));
    $finish;
end

task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
    WaitClocks(10); 
endtask

function int max(int num1, int num2);
    return (num1 > num2) ? num1 : num2;    
endfunction

endmodule

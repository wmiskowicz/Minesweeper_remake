`timescale 1 ns / 1 ps

module vga_timing_tb;

import vga_pkg::*;
import logger_pkg::*;

localparam CLK_PERIOD = 25ns;

logic clk;
logic rst;
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
    InitReset();
    `log_info("Starting test");
    WaitClocks(HCOUNT_MAX * VCOUNT_MAX);
    $finish;
end

always @(posedge clk) begin
    if (!rst) begin
        if (vga_test_if.out.hcount >= HSYNC_START && vga_test_if.out.hcount <= HSYNC_STOP) begin
            `check_eq(vga_test_if.out.hsync, 1'b1);
        end
        else begin
            `check_eq(vga_test_if.out.hsync, 1'b0);
        end

        if (vga_test_if.out.hcount >= HBLNK_START && vga_test_if.out.hcount <= HBLNK_STOP) begin
            `check_eq(vga_test_if.out.hblnk, 1'b1);
        end
        else begin
            `check_eq(vga_test_if.out.hblnk, 1'b0);
        end

        if (vga_test_if.out.vcount >= VSYNC_START && vga_test_if.out.vcount <= VSYNC_STOP) begin
            `check_eq(vga_test_if.out.vsync, 1'b1);
        end 
        else begin
            `check_eq(vga_test_if.out.vsync, 1'b0);
        end

        if (vga_test_if.out.vcount >= VBLNK_START && vga_test_if.out.vcount <= VBLNK_STOP) begin
            `check_eq(vga_test_if.out.vblnk, 1'b1);
        end
        else begin
            `check_eq(vga_test_if.out.vblnk, 1'b0);
        end
        `check_eq(vga_test_if.out.rgb, '0);
    end
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

endmodule

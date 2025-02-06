// DISCLAIMER: This code is provided as-is without warranty. Verify functionality before FPGA implementation.

`timescale 1ns / 1ps

module vga_double_buffer (
    input  logic clk,        // Clock
    input  logic rst,        // Reset
    vga_if.in  in,           // VGA input (timing & control)
    vga_if.out out           // VGA output (pixel data)
);

import vga_pkg::*;

/**
 * Double-Buffered Frame Memory (Stored in BRAM)
 */
logic [11:0] frame_buffer_A [0:HCOUNT_MAX - 1-1][0:VCOUNT_MAX - 1-1]; // Write Buffer
logic [11:0] frame_buffer_B [0:HCOUNT_MAX - 1-1][0:VCOUNT_MAX - 1-1]; // Read Buffer

logic buffer_select; // 0 = Display A, Write to B; 1 = Display B, Write to A
logic frame_ready;   // Frame completion flag

/**
 * Frame Swap Logic: Swap at End of Frame
 */
always_ff @(posedge clk) begin
    if (rst) begin
        buffer_select <= 0;
        frame_ready   <= 0;
    end
    else if (in.vcount == VCOUNT_MAX - 1 && in.hcount == HCOUNT_MAX - 1) begin
        frame_ready   <= 1;        // Mark frame as ready
        buffer_select <= ~buffer_select; // Swap buffers
    end
    else begin
        frame_ready <= 0;
    end
end

/**
 * Render Next Frame (Only in the Write Buffer)
 */
always_ff @(posedge clk) begin
    if (!buffer_select) begin
        frame_buffer_B[in.hcount][in.vcount] <= in.rgb;
    end else begin
        frame_buffer_A[in.hcount][in.vcount] <= in.rgb;
    end
end

/**
 * Display Frame (Read from Active Buffer)
 */
always_ff @(posedge clk) begin
    if (!buffer_select) begin
        out.rgb <= frame_buffer_A[in.hcount][in.vcount]; // Read from A
    end else begin
        out.rgb <= frame_buffer_B[in.hcount][in.vcount]; // Read from B
    end

    // Forward VGA Timing Signals
    out.hcount <= in.hcount;
    out.vcount <= in.vcount;
    out.hsync  <= in.hsync;
    out.vsync  <= in.vsync;
    out.hblnk  <= in.hblnk;
    out.vblnk  <= in.vblnk;
end

endmodule

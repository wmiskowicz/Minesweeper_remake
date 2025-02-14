`timescale 1ns / 1ps

module vga_out (
    input  logic clk,        
    input  logic rst,        
    vga_if.in  in,           
    vga_if.out out           
);

import vga_pkg::*;


logic [11:0] frame_buffer_A [0:HOR_TOTAL_TIME - 1][0:VER_TOTAL_TIME - 1]; 
logic [11:0] frame_buffer_B [0:HOR_TOTAL_TIME - 1][0:VER_TOTAL_TIME - 1]; 

logic buffer_select; 
logic frame_ready;   


// Swap frame
always_ff @(posedge clk) begin: buffer_swap_blk
    if (rst) begin
        buffer_select <= 1'b0;
        frame_ready   <= 1'b0;
    end
    else if (in.vcount == VCOUNT_MAX && in.hcount == HCOUNT_MAX) begin
        frame_ready   <= 1'b1;
        buffer_select <= ~buffer_select;
    end
    else begin
        frame_ready <= 1'b0;
    end
end

// Write buffer
always_ff @(posedge clk) begin: write_blk
    if (buffer_select) begin
        frame_buffer_B[in.hcount][in.vcount] <= in.rgb;
    end
    else begin
        frame_buffer_A[in.hcount][in.vcount] <= in.rgb;
    end
end

// Read buffer
always_ff @(posedge clk) begin: read_blk
    if (buffer_select) begin
        out.rgb <= frame_buffer_A[in.hcount][in.vcount];
    end else begin
        out.rgb <= frame_buffer_B[in.hcount][in.vcount];
    end

    out.hcount <= in.hcount;
    out.vcount <= in.vcount;
    out.hsync  <= in.hsync;
    out.vsync  <= in.vsync;
    out.hblnk  <= in.hblnk;
    out.vblnk  <= in.vblnk;
end

endmodule

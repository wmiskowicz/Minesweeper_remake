`timescale 1ns / 1ps

module vga_out (
    input  logic clk,        
    input  logic rst,        
    vga_if.in  in,           
    vga_if.out out           
);

import vga_pkg::*;

(* ram_style = "block" *) logic [11:0] line_buffer_A [0:HOR_TOTAL_TIME - 1]; 
(* ram_style = "block" *) logic [11:0] line_buffer_B [0:HOR_TOTAL_TIME - 1]; 

logic buffer_select; 

// Swap buffer
always_ff @(posedge clk) begin: buffer_swap_blk
    if (rst) begin
        buffer_select <= 1'b0;
    end
    else if (in.hcount == HCOUNT_MAX) begin
        buffer_select <= ~buffer_select;
    end
    else begin
    end
end

// Write buffer
always_ff @(posedge clk) begin: write_blk
    if (buffer_select) begin
        line_buffer_B[in.hcount] <= in.rgb;
    end
    else begin
        line_buffer_A[in.hcount] <= in.rgb;
    end
end

// Read buffer 
always_ff @(posedge clk) begin: read_blk
    if (buffer_select) begin
        out.rgb <= line_buffer_A[in.hcount];
    end else begin
        out.rgb <= line_buffer_B[in.hcount];
    end

    out.hcount <= in.hcount;
    out.vcount <= in.vcount;
    out.hsync  <= in.hsync;
    out.vsync  <= in.vsync;
    out.hblnk  <= in.hblnk;
    out.vblnk  <= in.vblnk;
end

endmodule

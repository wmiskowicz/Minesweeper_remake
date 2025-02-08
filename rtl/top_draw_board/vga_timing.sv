/**
 * Copyright (C) 2023  AGH University of Science and Technology
 * MTM UEC2 Projekt
 * Author: Piotr Kaczmarczyk
 * Modified: Wojciech Mskowicz
 * Description:
  Coding style: safe with FPGA sync reset
 * Vga timing controller.
 */

 `timescale 1 ns / 1 ps

module vga_timing (
    input  logic clk,
    input  logic rst,
    vga_if.out out
);

    import vga_pkg::*;

    always_ff @(posedge clk) begin : hcount_blk
        if (rst) begin
            out.hcount <= 0;
        end
        else if (out.hcount == H_TOTAL - 1) begin
            out.hcount <= 0;
        end
        else begin
            out.hcount <= out.hcount + 1;
        end
    end

    always_ff @(posedge clk) begin : vcount_blk
        if (rst) begin
            out.vcount <= 0;
        end
        else if (out.hcount == H_TOTAL - 1) begin
            if (out.vcount == V_TOTAL - 1) begin
                out.vcount <= 0;
            end
            else begin
                out.vcount <= out.vcount + 1;
            end
        end
    end

    always_ff @(posedge clk) begin : blank_sync_blk
        out.rgb <= '0;

        if (out.hcount >= HBLNK_START && out.hcount <= HBLNK_STOP) begin
            out.hblnk <= 1'b1;
        end
        else begin
            out.hblnk <= 1'b0;
        end

        if ((out.hcount >= HSYNC_START) && (out.hcount <= HSYNC_STOP)) begin
            out.hsync <= 1'b1;
        end
        else begin
            out.hsync <= 1'b0;
        end

        if (out.vcount >= VBLNK_START && out.vcount <= VBLNK_STOP) begin
            out.vblnk <= 1'b1;
        end
        else begin
            out.vblnk <= 1'b0;
        end

        if ((out.vcount >= VSYNC_START) && (out.vcount <= VSYNC_STOP)) begin
            out.vsync <= 1'b1;
        end
        else begin
            out.vsync <= 1'b0;
        end
    end

endmodule

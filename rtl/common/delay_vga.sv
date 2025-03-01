`timescale 1 ns / 1 ps

module delay_vga (
    input logic  clk,
    input logic rst,
    vga_if.in in,
    vga_if.out out
);

always_ff @(posedge clk) begin : delay_ff_blk
    if (rst) begin
        out.vcount <= '0;
        out.vsync <= '0;
        out.vblnk <= '0;
        out.hcount <= '0;
        out.hsync <= '0;
        out.hblnk <= '0;
        out.rgb <= '0;

    end else begin
        out.vcount <= in.vcount;
        out.vsync <= in.vsync;
        out.vblnk <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync <= in.hsync;
        out.hblnk <= in.hblnk;
        out.rgb <= in.rgb;
    end
end
endmodule
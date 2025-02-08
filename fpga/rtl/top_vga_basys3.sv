/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2023  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 * Wojciech Miskowicz
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

`timescale 1 ns / 1 ps

module top_vga_basys3 (
    input  wire clk,
    input  wire btnL,
    input  wire btnC,
    input  wire btnR,
    input  wire btnD,
    input  wire tim_stop,
    inout  wire PS2Clk,
    inout  wire PS2Data,

    output wire Vsync,
    output wire Hsync,
    output wire [3:0] vgaRed,    
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire JA1,
    output wire [6:0] seg,
    output wire [3:0] an
);


/**
 * Local variables and signals
 */

wire clk100MHz, clk88MHz;
wire locked;
wire pclk;
wire pclk_mirror;
wire [2:0] btnS;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)
logic [7:0] safe_start = 0;

/**
 * Signals assignments
 */



/**
 * FPGA submodules placement
 */

// Mirror pclk on a pin for use by the testbench;
// not functionally required for this design to work.

 clk_wiz_0 clk0_wiz(
    // Clock out ports
  .clk100MHz(clk100MHz),
  .clk90MHz(clk88MHz),
  // Status and control signals
  .locked(locked),
  .clk(clk)
);

/**
 *  Project functional top module
 */

top_vga u_top_vga (
    .clk(clk88MHz),
    .ps2_clk(PS2Clk),
    .ps2_data(PS2Data),
    .sseg(seg),
    .an(an),
    .rst(btnD),
    .r(vgaRed),
    .g(vgaGreen),
    .b(vgaBlue),
    .hs(Hsync),
    .vs(Vsync)
);

endmodule

/**
 * Copyright (C) 2023  AGH University of Science and Technology
 * MTM UEC2
 * Author: Robert Szczygiel
 * Modified: Piotr Kaczmarczyk, Wojciech Miskowicz
 * 
 * Description:
 * This is the ROM for a 48x48 image.
 * The input 'address' is a 12-bit number, composed of the concatenated
 * 6-bit y and 6-bit x pixel coordinates.
 * The output 'rgb' is a 12-bit number with concatenated
 * red, green, and blue color values (4-bit each).
 */

 module image_rom #(
  parameter PATH = "../../rtl/top_vga/data/bomb.data",
  parameter MEM_SIZE = 4096
 ) (
  input  logic clk,
  input  logic [11:0] address,  // address = {addry[5:0], addrx[5:0]}
  output logic [11:0] rgb
);


// Local variables and signals

reg [11:0] rom [0:MEM_SIZE-1]; 

// Reading from memory
initial $readmemh(PATH, rom);

always_ff @(posedge clk) rgb <= rom[address];

endmodule

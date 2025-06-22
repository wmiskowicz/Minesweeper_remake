/**
 * Copyright (C) 2023  AGH University of Science and Technology
 * MTM UEC2
 * Author: Robert Szczygiel
 * Modified: Piotr Kaczmarczyk, Wojciech Miskowicz
 * 
 * Description:
 * Generic image ROM module.
 * The input 'address' is composed of the concatenated
 * y and x pixel coordinates.
 * The output 'rgb' is a 12-bit number with concatenated
 * red, green, and blue color values (4-bit each).
 */

module image_rom #(
  parameter PATH = "../../rtl/top_vga/data/bomb.data",
  parameter MEM_SIZE = 4096,
  parameter ADDR_WIDTH = 12      // Default for 64x64 image (6+6 bits)
) (
  input  logic clk,
  input  logic [ADDR_WIDTH-1:0] address,
  output logic [11:0] rgb
);

// ----- Local variables -----
reg [11:0] rom [0:MEM_SIZE-1]; 

// Reading from memory
initial begin
  $readmemh(PATH, rom);
end

always_ff @(posedge clk) begin
  rgb <= rom[address];
end

endmodule
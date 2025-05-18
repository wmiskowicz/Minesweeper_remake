//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   wishbone_board_mem.sv
 Author:        Wojciech Miskowicz
 Description:   Custom wishbone slave module containing the game board.
 */
//////////////////////////////////////////////////////////////////////////////
`include "wishbone_defs.svh"

module wishbone_board_mem #(
  parameter BOARD_SIZE = 16
) (
  input logic clk,
  input logic rst,
  wishbone_if.slave slave
);


// ----- Local variables -----
field_t board_mem [15:0][15:0];

logic [3:0] row;
logic [3:0] col;


// ----- Signal assignments -----
assign row = slave.adr_o[7:4];
assign col = slave.adr_o[3:0];
assign slave.stall_i = 1'b0;


always_ff @(posedge clk) begin
  if(rst) begin
    for(int i=0; i < BOARD_SIZE; i++)
      for(int j=0; j < BOARD_SIZE; j++) 
        board_mem[i][j] <= 8'b0;
  end
  else if (slave.cyc_o && slave.stb_o && slave.we_o) begin
    board_mem[row][col] <= field_t'(slave.dat_o[7:0]);
  end
end

// Read
always_comb slave.dat_i = {8'b0, field_t'(board_mem[row][col])};

// Acknowledge
always_ff @(posedge clk) slave.ack_i <= slave.cyc_o && slave.stb_o;


endmodule
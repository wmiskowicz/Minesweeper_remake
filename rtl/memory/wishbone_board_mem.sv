
`include "wishbone_defs.svh"
module wishbone_board_mem #(
  parameter BOARD_SIZE = 16
) (
  input logic clk, 
  input logic rst,
  wishbone_if.slave slave_wr,
  wishbone_if.slave slave_rd
);

  field_t board_mem [15:0][15:0];

  logic [3:0] row_w;
  logic [3:0] col_w;
  logic [3:0] row_r;
  logic [3:0] col_r;

  assign row_w = slave_wr.adr_o[7:4];
  assign col_w = slave_wr.adr_o[3:0];
  assign row_r = slave_rd.adr_o[7:4];
  assign col_r = slave_rd.adr_o[3:0];

  logic grant_w, grant_r;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      grant_w <= 1'b0;
      grant_r <= 1'b0;
    end else begin
      if (slave_wr.cyc_o && !slave_rd.cyc_o) begin
        grant_w <= 1'b1;
        grant_r <= 1'b0;
      end else if (slave_rd.cyc_o && !slave_wr.cyc_o) begin
        grant_w <= 1'b0;
        grant_r <= 1'b1;
      end
    end
  end

  assign slave_wr.stall_i = grant_r;
  assign slave_rd.stall_i = grant_w;

  always_ff @(posedge clk) begin
    if(rst) begin
      for(int i=0; i < BOARD_SIZE; i++) 
        for(int j=0; j < BOARD_SIZE; j++) board_mem[i][j] <= 8'b0;
    end
    if (!slave_wr.stall_i && slave_wr.stb_o && slave_wr.we_o) begin
      board_mem[row_w][col_w] <= field_t'(slave_wr.dat_o);
    end
  end

  always_ff @(posedge clk) begin
    if (!slave_rd.stall_i && slave_rd.stb_o && !slave_rd.we_o) begin
      slave_rd.dat_i <= field_t'(board_mem[row_r][col_r]);
    end
  end

  always_ff @(posedge clk) begin
    slave_wr.ack_i <= !slave_wr.stall_i && slave_wr.stb_o;
    slave_rd.ack_i <= !slave_rd.stall_i && slave_rd.stb_o;
  end

endmodule

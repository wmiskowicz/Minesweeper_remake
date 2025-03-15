
`include "wishbone_defs.svh"
module wishbone_board_mem #(
  parameter BOARD_SIZE = 16
) (
  input logic clk, rst,
  wishbone_if.slave master_w,
  wishbone_if.slave master_r
);

  (* ram_style = "block" *)
  field_t board_mem [15:0][15:0];

  wire [3:0] row_w = master_w.adr_o[7:4];
  wire [3:0] col_w = master_w.adr_o[3:0];
  wire [3:0] row_r = master_r.adr_o[7:4];
  wire [3:0] col_r = master_r.adr_o[3:0];

  logic grant_w, grant_r;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      grant_w <= 1'b0;
      grant_r <= 1'b0;
    end else begin
      if (master_w.cyc_o && !master_r.cyc_o) begin
        grant_w <= 1'b1;
        grant_r <= 1'b0;
      end else if (master_r.cyc_o && !master_w.cyc_o) begin
        grant_w <= 1'b0;
        grant_r <= 1'b1;
      end
    end
  end

  assign master_w.stall_i = grant_r;
  assign master_r.stall_i = grant_w;

  always_ff @(posedge clk) begin
    if(rst) begin
      for(int i=0; i < BOARD_SIZE; i++) 
        for(int j=0; j < BOARD_SIZE; j++) board_mem[i][j] <= 8'b0;
    end
    if (!master_w.stall_i && master_w.stb_o && master_w.we_o) begin
      board_mem[row_w][col_w] <= field_t'(master_w.dat_o);
    end
  end

  always_ff @(posedge clk) begin
    if (!master_r.stall_i && master_r.stb_o && !master_r.we_o) begin
      master_r.dat_i <= field_t'(board_mem[row_r][col_r]);
    end
  end

  always_ff @(posedge clk) begin
    master_w.ack_i <= !master_w.stall_i && master_w.stb_o;
    master_r.ack_i <= !master_r.stall_i && master_r.stb_o;
  end

endmodule

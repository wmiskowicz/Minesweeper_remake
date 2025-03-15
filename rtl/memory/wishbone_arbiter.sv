module wishbone_arbiter (
  input logic clk, rst,
  wishbone_if.master master_0,
  wishbone_if.master master_1,
  wishbone_if.slave slave_if
);

  logic grant_0, grant_1;
  logic last_granted;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      grant_0 <= 1'b1;
      grant_1 <= 1'b0;
      last_granted <= 1'b0;
    end else begin
      if (master_0.cyc_o && master_1.cyc_o) begin
        if (!last_granted) begin
          grant_0 <= 1'b1;
          grant_1 <= 1'b0;
        end else begin
          grant_0 <= 1'b0;
          grant_1 <= 1'b1;
        end
        last_granted <= ~last_granted;
      end else begin
        grant_0 <= master_0.cyc_o;
        grant_1 <= master_1.cyc_o;
      end
    end
  end

  assign slave_if.adr_o = grant_0 ? master_0.adr_o : master_1.adr_o;
  assign slave_if.dat_o = grant_0 ? master_0.dat_o : master_1.dat_o;
  assign slave_if.we_o  = grant_0 ? master_0.we_o  : master_1.we_o;
  assign slave_if.stb_o = grant_0 ? master_0.stb_o : master_1.stb_o;
  assign slave_if.cyc_o = grant_0 ? master_0.cyc_o : master_1.cyc_o;

  assign master_0.dat_i = slave_if.dat_i;
  assign master_1.dat_i = slave_if.dat_i;
  assign master_0.ack_i = grant_0 ? slave_if.ack_i : 1'b0;
  assign master_1.ack_i = grant_1 ? slave_if.ack_i : 1'b0;
  assign master_0.stall_i = grant_0 ? slave_if.stall_i : 1'b1;
  assign master_1.stall_i = grant_1 ? slave_if.stall_i : 1'b1;

endmodule

module wishbone_arbiter (
  input logic clk, rst,
  wishbone_if.master master_prior,
  wishbone_if.master master_2,
  wishbone_if.slave slave_if
);

  logic grant_prior, grant_2;
  logic last_granted;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      grant_prior <= 1'b1;
      grant_2 <= 1'b0;
      last_granted <= 1'b0;
    end else begin
      if (master_prior.cyc_o && master_2.cyc_o) begin
        if (!last_granted) begin
          grant_prior <= 1'b1;
          grant_2 <= 1'b0;
        end else begin
          grant_prior <= 1'b0;
          grant_2 <= 1'b1;
        end
        last_granted <= ~last_granted;
      end else begin
        grant_prior <= master_prior.cyc_o;
        grant_2 <= master_2.cyc_o;
      end
    end
  end

  assign slave_if.adr_o = grant_prior ? master_prior.adr_o : master_2.adr_o;
  assign slave_if.dat_o = grant_prior ? master_prior.dat_o : master_2.dat_o;
  assign slave_if.we_o  = grant_prior ? master_prior.we_o  : master_2.we_o;
  assign slave_if.stb_o = grant_prior ? master_prior.stb_o : master_2.stb_o;
  assign slave_if.cyc_o = grant_prior ? master_prior.cyc_o : master_2.cyc_o;

  assign master_prior.dat_i = slave_if.dat_i;
  assign master_2.dat_i = slave_if.dat_i;

  assign master_prior.ack_i = grant_prior ? slave_if.ack_i : 1'b0;
  assign master_2.ack_i = grant_2 ? slave_if.ack_i : 1'b0;

  assign master_prior.stall_i = grant_prior ? slave_if.stall_i : 1'b1;
  assign master_2.stall_i = grant_2 ? slave_if.stall_i : 1'b1;

endmodule

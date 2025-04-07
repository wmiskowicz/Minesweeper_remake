module wishbone_arbiter (
  input logic clk, rst,
  wishbone_if.slave master_prior,  // Highest priority master
  wishbone_if.slave master_2,     // Medium priority master
  wishbone_if.slave master_3,     // Lowest priority master
  wishbone_if.master slave_if
);

  typedef enum logic [1:0] {
    PRIOR_MASTER = 2'b00,
    MASTER_2     = 2'b01,
    MASTER_3     = 2'b10,
    NO_MASTER    = 2'b11
  } master_select_t;

  master_select_t current_master, next_master;

  // Arbitration logic
  always_comb begin
    next_master = current_master;  // Default: keep current master
    
    // Priority-based arbitration
    if (master_prior.cyc_o) begin
      next_master = PRIOR_MASTER;
    end 
    else if (master_2.cyc_o) begin
      next_master = MASTER_2;
    end 
    else if (master_3.cyc_o) begin
      next_master = MASTER_3;
    end 
    else begin
      next_master = NO_MASTER;
    end

    // Don't switch masters mid-transaction
    if ((current_master != NO_MASTER) && 
        ((current_master == PRIOR_MASTER && master_prior.cyc_o) ||
         (current_master == MASTER_2 && master_2.cyc_o) ||
         (current_master == MASTER_3 && master_3.cyc_o))) begin
      next_master = current_master;
    end
  end

  // Master selection register
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      current_master <= NO_MASTER;
    end else begin
      current_master <= next_master;
    end
  end

  // Slave interface connections
  always_comb begin
    case (current_master)
      PRIOR_MASTER: begin
        slave_if.adr_o = master_prior.adr_o;
        slave_if.dat_o = master_prior.dat_o;
        slave_if.we_o  = master_prior.we_o;
        slave_if.stb_o = master_prior.stb_o;
        slave_if.cyc_o = master_prior.cyc_o;
      end
      MASTER_2: begin
        slave_if.adr_o = master_2.adr_o;
        slave_if.dat_o = master_2.dat_o;
        slave_if.we_o  = master_2.we_o;
        slave_if.stb_o = master_2.stb_o;
        slave_if.cyc_o = master_2.cyc_o;
      end
      MASTER_3: begin
        slave_if.adr_o = master_3.adr_o;
        slave_if.dat_o = master_3.dat_o;
        slave_if.we_o  = master_3.we_o;
        slave_if.stb_o = master_3.stb_o;
        slave_if.cyc_o = master_3.cyc_o;
      end
      default: begin
        slave_if.adr_o = '0;
        slave_if.dat_o = '0;
        slave_if.we_o  = '0;
        slave_if.stb_o = '0;
        slave_if.cyc_o = '0;
      end
    endcase
  end

  // Master interface connections
  assign master_prior.dat_i = slave_if.dat_i;
  assign master_2.dat_i     = slave_if.dat_i;
  assign master_3.dat_i     = slave_if.dat_i;

  assign master_prior.ack_i = (current_master == PRIOR_MASTER) ? slave_if.ack_i : 1'b0;
  assign master_2.ack_i     = (current_master == MASTER_2)     ? slave_if.ack_i : 1'b0;
  assign master_3.ack_i     = (current_master == MASTER_3)     ? slave_if.ack_i : 1'b0;

  assign master_prior.stall_i = (current_master == PRIOR_MASTER) ? slave_if.stall_i : 1'b1;
  assign master_2.stall_i     = (current_master == MASTER_2)     ? slave_if.stall_i : 1'b1;
  assign master_3.stall_i     = (current_master == MASTER_3)     ? slave_if.stall_i : 1'b1;

endmodule
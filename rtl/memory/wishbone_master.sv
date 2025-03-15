//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Wishbone master
 Author:        Wojciech Miskowicz
 Description:   Implements a wishbone compatible master.
 */
//////////////////////////////////////////////////////////////////////////////
`include "wishbone_defs.svh"
module wishbone_master (
  input  wire clk,  
  input  wire rst,  

  input  logic       burst_active, 
  input  logic [7:0] write_data,
  input  logic [7:0] write_addr,
  input  logic       write_en,
  output logic       write_ready,
 
  output logic [7:0] read_data,
  input  logic [7:0] read_addr,
  input  logic       read_en,
  output logic       read_ready,

  wishbone_if.master wb_master
);


master_state_t master_state;


always_comb begin
  
end 
    
// dodać logikę cyc_o tak, żeby był wysoki kiedy trwa burst (jak np podczas odczytu / zapisu całej tablicy)
always_ff @(posedge clk) begin
  if(rst) begin
    wb_master.adr_o <= '0;
    wb_master.cyc_o <= '0;
    wb_master.dat_o <= '0;
    wb_master.stb_o <= '0;
    wb_master.we_o  <= '0;
    write_ready     <= 1'b0;
    read_ready      <= 1'b0;
    master_state    <= IDLE;
  end
  else begin
    case (master_state)
      IDLE: begin
        wb_master.stb_o <= 1'b0;
        wb_master.cyc_o <= burst_active;
        wb_master.we_o  <= 1'b0;
        write_ready     <= 1'b0;
        read_ready      <= 1'b0;

        if (write_en || read_en) begin
          wb_master.we_o  <= write_en;
          wb_master.adr_o <= write_en ? write_addr : read_addr;
          wb_master.dat_o <= write_data;
          wb_master.stb_o <= 1'b1;
          wb_master.cyc_o <= 1'b1;
          master_state    <= BUS_WAIT; 
        end
      end
      BUS_WAIT: begin
        if (!wb_master.stall_i && wb_master.ack_i) begin 

          wb_master.stb_o <= 1'b0;
          wb_master.cyc_o <= burst_active;

          write_ready <= wb_master.we_o;
		      read_ready  <= !wb_master.we_o;
          read_data   <= wb_master.dat_i;

          master_state <= IDLE;
        end
      end
      default: master_state <= IDLE;
    endcase
  end
end

endmodule
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

  wishbone_if.master master_wb
);


master_state_t master_state;


always_comb begin
  
end 
    
// dodać logikę cyc_o tak, żeby był wysoki kiedy trwa burst (jak np podczas odczytu / zapisu całej tablicy)
always_ff @(posedge clk) begin
  if(rst) begin
    master_wb.adr_o <= '0;
    master_wb.cyc_o <= '0;
    master_wb.dat_o <= '0;
    master_wb.stb_o <= '0;
    master_wb.we_o  <= '0;
    write_ready     <= 1'b0;
    read_ready      <= 1'b0;
    master_state    <= IDLE;
  end
  else begin
    case (master_state)
      IDLE: begin
        master_wb.stb_o <= 1'b0;
        master_wb.cyc_o <= burst_active;
        master_wb.we_o  <= 1'b0;
        write_ready     <= 1'b0;
        read_ready      <= 1'b0;

        if (write_en || read_en) begin
          master_wb.we_o  <= write_en;
          master_wb.adr_o <= write_en ? write_addr : read_addr;
          master_wb.dat_o <= write_data;
          master_wb.stb_o <= 1'b1;
          master_wb.cyc_o <= 1'b1;
          master_state    <= BUS_WAIT; 
        end
      end
      BUS_WAIT: begin
        if (!master_wb.stall_i && master_wb.ack_i) begin 

          master_wb.stb_o <= 1'b0;
          master_wb.cyc_o <= burst_active;

          write_ready <= master_wb.we_o;
		      read_ready  <= !master_wb.we_o;
          read_data   <= master_wb.dat_i;

          master_state <= IDLE;
        end
      end
      default: master_state <= IDLE;
    endcase
  end
end

endmodule
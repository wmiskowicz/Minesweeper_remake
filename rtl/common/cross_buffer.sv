module cross_buffer (
    input  logic slow_clk,
    input  logic rst,
    input  logic clk100MHz,
    input  logic [11:0] xpos_in,
    input  logic [11:0] ypos_in,
    output logic [11:0] xpos_out,
    output logic [11:0] ypos_out
  );
  
    logic [11:0] ypos_mem [3:0];
    logic [11:0] xpos_mem [3:0];
    logic [1:0] wr_ind, wr_ind_sync, rd_ind;
    logic wr_toggle, wr_toggle_sync, wr_toggle_sync2, wr_toggle_last;
  
    // 100 MHz Domain: Write Data into Memory
    always_ff @(posedge clk100MHz or posedge rst) begin
      if (rst) begin
        for (int i = 0; i < 4; i++) begin
          xpos_mem[i] <= 12'd0;
          ypos_mem[i] <= 12'd0;
        end
        wr_ind <= 0;
        wr_toggle <= 0;
      end 
      else begin
        xpos_mem[wr_ind] <= xpos_in;
        ypos_mem[wr_ind] <= ypos_in;
        wr_ind <= wr_ind + 1;
        wr_toggle <= ~wr_toggle; // Toggle to indicate new data
      end
    end
  
    // Synchronize wr_toggle to slow_clk
    always_ff @(posedge slow_clk or posedge rst) begin
      if (rst) begin
        wr_toggle_sync  <= 0;
        wr_toggle_sync2 <= 0;
        wr_toggle_last  <= 0;
        rd_ind <= 0;
      end 
      else begin
        wr_toggle_sync  <= wr_toggle;
        wr_toggle_sync2 <= wr_toggle_sync;
        wr_toggle_last  <= wr_toggle_sync2;
        
        // Read only when wr_toggle changes (new data available)
        if (wr_toggle_sync2 != wr_toggle_last) begin
          rd_ind <= wr_ind_sync; 
        end
      end
    end
  
    // Synchronize wr_ind from 100 MHz to 74.25 MHz
    always_ff @(posedge slow_clk or posedge rst) begin
      if (rst) begin
        wr_ind_sync <= 0;
      end else begin
        wr_ind_sync <= wr_ind;
      end
    end
  
    // Output the stable read data
    always_ff @(posedge slow_clk or posedge rst) begin
      if (rst) begin
        xpos_out <= 12'd0;
        ypos_out <= 12'd0;
      end 
      else begin
        xpos_out <= xpos_mem[rd_ind];
        ypos_out <= ypos_mem[rd_ind];
      end
    end
  
  endmodule
  
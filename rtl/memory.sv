module board_memory (
  whishbone_if.slave wb
);

// Typedef for 8-bit field structure
typedef struct packed {
  logic        mine;       // 1-bit: Mine status
  logic        flag;       // 1-bit: Flag status
  logic        defused;    // 1-bit: Defused status
  logic [3:0]  mine_ind;   // 4-bit: Mine index
  logic        placeholder;// 1-bit: Reserved
} field_t;

// 16x16 memory array of Field
field_t board [15:0][15:0];

// Extract row and column from 8-bit address (4 bits each)
wire [3:0] row = wb.ADR_O[7:4];
wire [3:0] col = wb.ADR_O[3:0];

// Register to hold read data
always_ff @(posedge wb.CLK_I or posedge wb.RST_I) begin
  if (wb.RST_I) begin
      wb.DAT_I <= 8'b0;
      wb.ACK_I <= 0;
  end else begin
      wb.ACK_I <= 0;
      if (wb.CYC_O && wb.STB_O) begin
          if (wb.WE_O) begin
              // Write Operation
              board[row][col] <= Field'(wb.DAT_O);
          end else begin
              // Read Operation
              wb.DAT_I <= board[row][col];
          end
          wb.ACK_I <= 1; // Acknowledge transaction
      end
  end
end

endmodule

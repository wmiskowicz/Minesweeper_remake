module board_memory_with_arbiter (
  input logic clk, rst,
  wishbone_if.master master1, // Writing Master
  wishbone_if.master master2  // Reading Master
);

typedef struct packed {
  logic        mine;
  logic        flag;
  logic        defused;
  logic [3:0]  mine_ind;
  logic        placeholder;
} field_t;

(* ram_style = "block" *)
field_t board_mem [15:0][15:0];

// Extract row/col from Wishbone address
wire [3:0] row1 = master1.ADR_O[7:4];
wire [3:0] col1 = master1.ADR_O[3:0];
wire [3:0] row2 = master2.ADR_O[7:4];
wire [3:0] col2 = master2.ADR_O[3:0];

logic master1_granted, master2_granted;

// Write master priority
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
      master1_granted <= 1'b1;
      master2_granted <= 1'b0;
  end else begin
      if (master1.CYC_O && !master2.CYC_O)
          master1_granted <= 1'b1;
      else if (master2.CYC_O && !master1.CYC_O)
          master2_granted <= 1'b1;
  end
end

// Write logic (Only Master 1 can write)
always_ff @(posedge clk) begin
  if (master1.CYC_O && master1.STB_O && master1.WE_O && master1_granted) begin
      board_mem[row1][col1] <= field_t'(master1.DAT_O);
  end
end

// Read logic for both masters
always_ff @(posedge clk) begin
  if (master1.CYC_O && master1.STB_O && !master1.WE_O && master1_granted) 
      master1.DAT_I <= board_mem[row1][col1];
      
  if (master2.CYC_O && master2.STB_O && !master2.WE_O && master2_granted) 
      master2.DAT_I <= board_mem[row2][col2];
end

// Acknowledge logic
always_ff @(posedge clk) begin
  master1.ACK_I <= master1.CYC_O && master1.STB_O && master1_granted;
  master2.ACK_I <= master2.CYC_O && master2.STB_O && master2_granted;
end

endmodule

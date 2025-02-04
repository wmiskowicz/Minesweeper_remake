interface whishbone_if (
  input logic CLK_I, 
  input logic RST_I
);

  logic [7:0]  DAT_I;   // Data input to master
  logic [7:0]  DAT_O;   // Data output from master
  logic [7:0]  ADR_O;   // Address bus (8-bit for 16x16 board)
  logic        WE_O;    // Write enable (1 = write, 0 = read)
  logic        STB_O;   // Strobe signal (indicates valid transaction)
  logic        ACK_I;   // Acknowledge from the slave
  logic        CYC_O;   // Cycle valid (keeps the bus active)

  modport master (
      output ADR_O, DAT_O, WE_O, STB_O, CYC_O,
      input  DAT_I, ACK_I
  );

  modport slave (
      input ADR_O, DAT_O, WE_O, STB_O, CYC_O,
      output DAT_I, ACK_I
  );

endinterface

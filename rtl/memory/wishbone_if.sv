interface wishbone_if (
  // input logic CLK_I, 
  // input logic RST_I
);

  logic [15:0] dat_i;   // Data input to master
  logic [15:0] dat_o;   // Data output from master
  logic [7:0]  adr_o;   // Address bus (8-bit for 16x16 board)
  logic        we_o;    // Write enable (1 = write, 0 = read)
  logic        stb_o;   // Strobe signal (indicates valid transaction)
  logic        ack_i;   // Acknowledge from the slave
  logic        cyc_o;   // Cycle valid (keeps the bus active)
  logic        stall_i;

  modport master (
      output adr_o, dat_o, we_o, stb_o, cyc_o,
      input  dat_i, ack_i, stall_i
  );

  modport slave (
      input adr_o, dat_o, we_o, stb_o, cyc_o,
      output dat_i, ack_i, stall_i
  );

endinterface

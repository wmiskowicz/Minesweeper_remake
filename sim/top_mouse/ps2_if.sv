
`ifndef PS2_IF_SV
`define PS2_IF_SV

interface ps2_if;
  // Bidirectional open-drain signals
  wire clk;
  wire data;

  // Internal drivers
  logic clk_drive = 1'b1;
  logic data_drive = 1'b1;

  assign clk = (clk_drive === 1'b0) ? 1'b0 : 1'bz;
  assign data = (data_drive === 1'b0) ? 1'b0 : 1'bz;

  // For monitoring
  logic clk_in;
  logic data_in;

  assign clk_in = clk;
  assign data_in = data;

  modport master (
    output clk_drive,
    output data_drive,
    input  clk_in,
    input  data_in
  );

  modport slave (
    input  clk_drive,
    input  data_drive,
    output clk_in,
    output data_in
  );

  initial begin
    // Ensure signals start high (pulled up)
    clk_drive = 1'b1;
    data_drive = 1'b1;
  end

endinterface

`endif



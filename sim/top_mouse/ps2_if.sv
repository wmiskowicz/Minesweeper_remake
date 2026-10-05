`ifndef PS2_IF_SV
`define PS2_IF_SV

interface ps2_if;
  // Drive controls: 1=high-Z/release, 0=drive low (open-drain)
  logic clk_drv;
  logic data_drv;

  // Actual bus line states. These are NOT driven here: the testbench
  // top level resolves them from clk_drv/data_drv together with the
  // DUT's own open-drain drive and the bus pull-ups, then drives them
  // in from outside. Driving them here too would create a second
  // driver on the same net and race with the DUT's value (resolving
  // to 'x' whenever they disagree).
  wire clk_in;
  wire data_in;

   // Modport for mouse BFM
  modport mouse (
    output clk_drv,
    output data_drv,
    input clk_in,
    input data_in
  );
  
  // Modport for host (DUT)
  modport host (
    output clk_drv,
    output data_drv,
    input clk_in,
    input data_in
  );

    initial begin
    clk_drv = 1'b1;  // Start in released state
    data_drv = 1'b1; // Start in released state
  end

endinterface

`endif

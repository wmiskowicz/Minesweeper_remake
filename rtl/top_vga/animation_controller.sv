// Animation controller module
module animation_controller (
  input clk,
  input rst,
  input trigger,          // When to start animation
  output logic [3:0] frame_num  // Current animation frame
);

// 60Hz animation timing (16.6ms per frame)
localparam CLOCK_FREQ = 100_000_000;
localparam ANIMATION_FRAMERATE = 60; 
localparam CLOCKS_PER_FRAME = CLOCK_FREQ/ANIMATION_FRAMERATE;

logic [31:0] counter;

always_ff @(posedge clk) begin
  if (rst) begin
      counter <= 0;
      frame_num <= 0;
  end else if (trigger) begin
      if (counter >= CLOCKS_PER_FRAME-1) begin
          counter <= 0;
          frame_num <= frame_num + 1;
      end else begin
          counter <= counter + 1;
      end
  end
end
endmodule
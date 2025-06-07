//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   time_controller
 Author:        Wojciech Miskowicz
 Description:   A module for controlling basic timer
 */
//////////////////////////////////////////////////////////////////////////////

module time_controller
(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire        stop,
  input  wire        retry,
  input  wire  [7:0] sec_to_count,

  output logic [7:0] second_ctr,
  output logic       time_elapsed
);


// ----- Local variables -----
logic [31:0] tick_ctr;

enum logic [2:0]{
  IDLE,
  COUNT,
  SEC_DONE,
  STOP,
  ELAPSED
} state;


always_ff @(posedge clk) begin
  if(rst) begin
    state        <= IDLE;
    second_ctr   <= 8'd0;
    tick_ctr     <= 32'd0;
    time_elapsed <= 1'b0;
  end
  else begin
    case(state)
      IDLE: begin
        state        <= start ? COUNT : IDLE;
        tick_ctr     <= 28'd100_000_000;
        second_ctr   <= sec_to_count;
        time_elapsed <= 1'b0;
      end

      COUNT: begin
        if(stop)begin
          state <= STOP;
        end
        else if (tick_ctr == 32'd0) begin
          state    <= SEC_DONE;
          tick_ctr <= 32'd0;
        end
        else begin
          state    <= COUNT;
          tick_ctr <= tick_ctr - 32'd1;
        end
        time_elapsed <= 1'b0;
      end

      SEC_DONE: begin
        if(second_ctr > 0) begin
          tick_ctr   <= 28'd100_000_000;
          second_ctr <= second_ctr - 8'd1;
          state      <= COUNT;
        end
        else begin
          tick_ctr     <= 32'd0;
          time_elapsed <= 1'b1;
          state        <= ELAPSED;
        end
      end

      STOP: begin
        time_elapsed <= 1'b0;
        state        <= stop ? STOP : COUNT;
      end

      ELAPSED: begin
        tick_ctr     <= 32'd0;
        second_ctr   <= 8'd0;
        time_elapsed <= 1'b1;
        state        <= retry ? IDLE : ELAPSED;
      end

      default: begin
        tick_ctr     <= 32'd0;
        second_ctr   <= 8'd0;
        time_elapsed <= 1'b0;
        state        <= IDLE;
      end
    endcase
  end
end

endmodule

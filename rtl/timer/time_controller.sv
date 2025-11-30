//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   time_controller
 Author:        Wojciech Miskowicz
 Description:   A module for controlling basic timer
 */
//////////////////////////////////////////////////////////////////////////////

module time_controller #(
  parameter int F_CLK_HZ = 74_000_000
)
(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire        stop,
  input  wire        retry,
  input  wire  [7:0] sec_to_count,

  output logic [7:0] second_ctr,
  output logic [7:0] milisecond_ctr,
  output logic       time_elapsed
);

// ----- Local parameters -----
localparam int CLK_PERIOD_NS = real'(1_000_000_000 / real'(F_CLK_HZ));
localparam int SEC_TICK_NUM = 1_000_000_000 / CLK_PERIOD_NS;
localparam int MS_TICK_NUM = 10_000_000 / CLK_PERIOD_NS;
localparam [7:0] MS_VAL = 99;


// ----- Local variables -----
logic [31:0] tick_ctr;
logic [7:0]  ms_ctr_q;

enum logic [2:0]{
  IDLE,
  COUNT,
  SEC_DONE,
  MS_DONE,
  STOP,
  ELAPSED
} state;

// ----- Signal assignments -----
assign milisecond_ctr = ms_ctr_q;


always_ff @(posedge clk) begin
  if(rst) begin
    state        <= IDLE;
    second_ctr   <= 8'd0;
    tick_ctr     <= 32'd0;
    time_elapsed <= 1'b0;
    ms_ctr_q     <= MS_VAL;
  end
  else begin
    case(state)

      IDLE: begin
        state        <= start ? COUNT : IDLE;
        tick_ctr     <= MS_TICK_NUM;
        second_ctr   <= sec_to_count;
        time_elapsed <= 1'b0;
        ms_ctr_q     <= MS_VAL;
      end

      COUNT: begin
        if(stop)begin
          state <= STOP;
        end
        else if(retry) begin
          state <= IDLE;
        end
        else if (tick_ctr == 32'd0) begin

          if (ms_ctr_q > 8'd0) begin
            ms_ctr_q <= ms_ctr_q - 8'd1;
            tick_ctr <= MS_TICK_NUM;
          end
          else begin
            state    <= SEC_DONE;
            ms_ctr_q <= MS_VAL;
          end

        end
        else begin
          state    <= COUNT;
          tick_ctr <= tick_ctr - 32'd1;
        end
        time_elapsed <= 1'b0;
      end

      SEC_DONE: begin
        if(second_ctr > 0) begin
          tick_ctr   <= MS_TICK_NUM;
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

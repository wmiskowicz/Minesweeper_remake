//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   time_controller
 Author:        Wojciech Miskowicz
 Description:   A module for controlling basic timer
 */
//////////////////////////////////////////////////////////////////////////////

module time_controller #(
  parameter int F_CLK_HZ = 100_000_000
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
localparam real CLK_PERIOD_NS = real'(1_000_000_000 / real'(F_CLK_HZ));
localparam int MS_TICK_NUM = real'(10_000_000 / real'(CLK_PERIOD_NS));
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
} timer_state;

// ----- Signal assignments -----
assign milisecond_ctr = ms_ctr_q;

// Note: The module outputs the hundreds and tens of milliseconds.


always_ff @(posedge clk) begin
  if(rst) begin
    timer_state  <= IDLE;
    second_ctr   <= 8'd0;
    tick_ctr     <= 32'd0;
    time_elapsed <= 1'b0;
    ms_ctr_q     <= MS_VAL;
  end
  else begin
    case(timer_state)

      IDLE: begin
        timer_state  <= start ? COUNT : IDLE;
        tick_ctr     <= MS_TICK_NUM;
        second_ctr   <= sec_to_count - 8'd1;
        time_elapsed <= 1'b0;
        ms_ctr_q     <= MS_VAL;
      end

      COUNT: begin
        if(stop)begin
          timer_state <= STOP;
        end
        else if(retry) begin
          timer_state <= IDLE;
        end
        else if (tick_ctr == 32'd0) begin

          if (ms_ctr_q > 8'd0) begin
            ms_ctr_q <= ms_ctr_q - 8'd1;
            tick_ctr <= MS_TICK_NUM;
          end
          else begin
            timer_state <= SEC_DONE;
            ms_ctr_q    <= MS_VAL;
          end

        end
        else begin
          timer_state <= COUNT;
          tick_ctr    <= tick_ctr - 32'd1;
        end
        time_elapsed <= 1'b0;
      end

      SEC_DONE: begin
        if(second_ctr > 0) begin
          tick_ctr    <= MS_TICK_NUM;
          second_ctr  <= second_ctr - 8'd1;
          timer_state <= COUNT;
        end
        else begin
          tick_ctr     <= 32'd0;
          time_elapsed <= 1'b1;
          timer_state  <= ELAPSED;
        end
      end

      STOP: begin
        time_elapsed <= 1'b0;
        timer_state  <= stop ? STOP : COUNT;
      end

      ELAPSED: begin
        tick_ctr     <= 32'd0;
        second_ctr   <= 8'd0;
        time_elapsed <= 1'b1;
        timer_state  <= retry ? IDLE : ELAPSED;
      end

      default: begin
        tick_ctr     <= 32'd0;
        second_ctr   <= 8'd0;
        time_elapsed <= 1'b0;
        ms_ctr_q     <= MS_VAL;
        timer_state  <= IDLE;
      end
    endcase
  end
end

endmodule

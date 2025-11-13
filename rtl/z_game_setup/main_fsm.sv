//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game.
 */
//////////////////////////////////////////////////////////////////////////////
import game_pkg::*;

module main_fsm#(
  parameter int BANNER_DISP_CYC = 400_000_000
)(
  input  wire  clk,
  input  wire  rst,
  input  wire  [1:0] level,
  input  wire  timer_stop,
  input  wire  game_won,
  input  wire  game_lost,
  input  wire  back_to_menu,
  input  wire  retry,

  input wire   left,
  input wire   right,

  output logic [2:0] state_out,
  output logic [7:0] seconds_left,
  output logic       time_elapsed,

  wishbone_if.slave game_set_wb1,
  wishbone_if.slave game_set_wb2,
  wishbone_if.slave game_set_wb3
);


// ----- Local parameters -----
localparam NUMBER_OF_REGISTERS = 9;

localparam [7:0] ROW_COLUMN_NUMBER_ADDR = 8'h00;
localparam [7:0] MINE_NUM_ADDR          = 8'h02;
localparam [7:0] TIMER_SECONDS_ADDR     = 8'h04;
localparam [7:0] FIELD_SIZE_ADDR        = 8'h06;
localparam [7:0] BOARD_SIZE_ADDR        = 8'h08;
localparam [7:0] BOARD_XPOS_ADDR        = 8'h0A;
localparam [7:0] BOARD_YPOS_ADDR        = 8'h0C;
localparam [7:0] GAMES_WON_ADDR         = 8'h0E;
localparam [7:0] GAMES_LOST_ADDR        = 8'h10;



// ----- Local variables -----
logic [15:0] game_setup_mem [NUMBER_OF_REGISTERS-1:0];
logic [31:0] banner_cyc_ctr;


always_ff @(posedge clk) begin : fsm_blk
  if(rst) begin
    fsm_state <= BANNER;
    state_out <= BANNER;

    game_set_wb1.stall_i <= 1'b0;
    game_set_wb2.stall_i <= 1'b0;
    game_set_wb3.stall_i <= 1'b0;

    banner_cyc_ctr <= 32'b0;

    for(int i=0; i < NUMBER_OF_REGISTERS; i++) 
      game_setup_mem[i] <= 16'b0;
  end
  else begin
    state_out <= fsm_state;
    case(fsm_state)
      BANNER: begin
        if (banner_cyc_ctr >= BANNER_DISP_CYC || left || right) begin
          fsm_state <= MENU;
          banner_cyc_ctr <= 32'b0;
        end
        else 
          banner_cyc_ctr <= banner_cyc_ctr + 32'd1;
      end
      MENU: begin
        if(level > 0) begin
          fsm_state <= PLAY;
          game_set_wb1.stall_i <= 1'b1;
          game_set_wb2.stall_i <= 1'b1;
          game_set_wb3.stall_i <= 1'b1;
          case(level)
            2'd1: begin
              game_setup_mem[0] <= E_ROW_COLUMN_NUMBER;
              game_setup_mem[1] <= E_MINE_NUM;
              game_setup_mem[2] <= E_TIMER_SECONDS;
              game_setup_mem[3] <= E_FIELD_SIZE;
              game_setup_mem[4] <= E_BOARD_SIZE;
              game_setup_mem[5] <= E_BOARD_XPOS;
              game_setup_mem[6] <= E_BOARD_YPOS;
            end
            2'd2: begin
              game_setup_mem[0] <= M_ROW_COLUMN_NUMBER;
              game_setup_mem[1] <= M_MINE_NUM;
              game_setup_mem[2] <= M_TIMER_SECONDS;
              game_setup_mem[3] <= M_FIELD_SIZE;
              game_setup_mem[4] <= M_BOARD_SIZE;
              game_setup_mem[5] <= M_BOARD_XPOS;
              game_setup_mem[6] <= M_BOARD_YPOS;
            end
            2'd3: begin
              game_setup_mem[0] <= H_ROW_COLUMN_NUMBER;
              game_setup_mem[1] <= H_MINE_NUM;
              game_setup_mem[2] <= H_TIMER_SECONDS;
              game_setup_mem[3] <= H_FIELD_SIZE;
              game_setup_mem[4] <= H_BOARD_SIZE;
              game_setup_mem[5] <= H_BOARD_XPOS;
              game_setup_mem[6] <= H_BOARD_YPOS;
            end
            default: for(int i=0; i < NUMBER_OF_REGISTERS; i++) game_setup_mem[i] <= 16'hDEAD;

          endcase
        end
        else for(int i=0; i < NUMBER_OF_REGISTERS; i++) game_setup_mem[i] <= 16'b0;
      end
      PLAY: begin
        game_set_wb1.stall_i <= 1'b0;
        game_set_wb2.stall_i <= 1'b0;
        game_set_wb3.stall_i <= 1'b0;
        if(timer_stop)        fsm_state <= PAUSE;
        else if(back_to_menu) fsm_state <= MENU;
        else if(game_won)     fsm_state <= WIN;
        else if(game_lost || time_elapsed) fsm_state <= LOST;
      end
      PAUSE: begin 
        if(~timer_stop) 
          fsm_state <= PLAY;
        else if(back_to_menu)
          fsm_state <= MENU;
      end
      WIN: begin
        game_setup_mem[GAMES_WON_REG_NUM]++;
        fsm_state <= GAME_OVER;
      end
      LOST: begin
        game_setup_mem[GAMES_LOST_REG_NUM]++;
        fsm_state <= GAME_OVER;
      end
      GAME_OVER: begin
        if(back_to_menu) fsm_state <= MENU;
        else if (retry)  fsm_state <= PLAY;
      end
      default: fsm_state <= MENU;
    endcase
  end
end


top_timer u_top_timer(
  .clk   (clk),
  .rst   (rst || (fsm_state == MENU)),
  .start (fsm_state == PLAY), 
  .stop  (timer_stop),
  .retry (retry || (fsm_state == GAME_OVER)),   

  .sec_to_count (game_setup_mem[TIMER_SECONDS_REG_NUM][7:0]),
  .seconds_left (seconds_left),
  .time_elapsed (time_elapsed)
);



always_ff @(posedge clk) begin
  if(rst) begin
    game_set_wb1.ack_i <= 1'b0;
    game_set_wb1.dat_i <= 16'b0;
  end
  else if (!game_set_wb1.stall_i && game_set_wb1.stb_o && !game_set_wb1.we_o) begin
    game_set_wb1.ack_i <= 1'b1;

    case (game_set_wb1.adr_o)
      ROW_COLUMN_NUMBER_ADDR: game_set_wb1.dat_i <= game_setup_mem [ROW_COLUMN_NUMBER_REG_NUM];
      MINE_NUM_ADDR:          game_set_wb1.dat_i <= game_setup_mem [MINE_NUM_REG_NUM];
      TIMER_SECONDS_ADDR:     game_set_wb1.dat_i <= game_setup_mem [TIMER_SECONDS_REG_NUM];
      FIELD_SIZE_ADDR:        game_set_wb1.dat_i <= game_setup_mem [FIELD_SIZE_REG_NUM];
      BOARD_SIZE_ADDR:        game_set_wb1.dat_i <= game_setup_mem [BOARD_SIZE_REG_NUM];
      BOARD_XPOS_ADDR:        game_set_wb1.dat_i <= game_setup_mem [BOARD_XPOS_REG_NUM];
      BOARD_YPOS_ADDR:        game_set_wb1.dat_i <= game_setup_mem [BOARD_YPOS_REG_NUM];
      GAMES_WON_ADDR:         game_set_wb1.dat_i <= game_setup_mem [GAMES_WON_REG_NUM];
      GAMES_LOST_ADDR:        game_set_wb1.dat_i <= game_setup_mem [GAMES_LOST_REG_NUM];
      default:                game_set_wb1.dat_i <= 16'hDEAD;
    endcase
  end
  else begin
    game_set_wb1.ack_i <= 1'b0;
    game_set_wb1.dat_i <= 16'b0;
  end
end

always_ff @(posedge clk) begin
  if(rst) begin
    game_set_wb2.ack_i <= 1'b0;
    game_set_wb2.dat_i <= 16'b0;
  end
  else if (!game_set_wb2.stall_i && game_set_wb2.stb_o && !game_set_wb2.we_o) begin
    game_set_wb2.ack_i <= 1'b1;

    case (game_set_wb2.adr_o)
      ROW_COLUMN_NUMBER_ADDR: game_set_wb2.dat_i <= game_setup_mem [ROW_COLUMN_NUMBER_REG_NUM];
      MINE_NUM_ADDR:          game_set_wb2.dat_i <= game_setup_mem [MINE_NUM_REG_NUM];
      TIMER_SECONDS_ADDR:     game_set_wb2.dat_i <= game_setup_mem [TIMER_SECONDS_REG_NUM];
      FIELD_SIZE_ADDR:        game_set_wb2.dat_i <= game_setup_mem [FIELD_SIZE_REG_NUM];
      BOARD_SIZE_ADDR:        game_set_wb2.dat_i <= game_setup_mem [BOARD_SIZE_REG_NUM];
      BOARD_XPOS_ADDR:        game_set_wb2.dat_i <= game_setup_mem [BOARD_XPOS_REG_NUM];
      BOARD_YPOS_ADDR:        game_set_wb2.dat_i <= game_setup_mem [BOARD_YPOS_REG_NUM];
      GAMES_WON_ADDR:         game_set_wb2.dat_i <= game_setup_mem [GAMES_WON_REG_NUM];
      GAMES_LOST_ADDR:        game_set_wb2.dat_i <= game_setup_mem [GAMES_LOST_REG_NUM];
      default:                game_set_wb2.dat_i <= 16'hDEAD;
    endcase
  end
  else begin
    game_set_wb2.ack_i <= 1'b0;
    game_set_wb2.dat_i <= 16'b0;
  end
end

always_ff @(posedge clk) begin
  if(rst) begin
    game_set_wb3.ack_i <= 1'b0;
    game_set_wb3.dat_i <= 16'b0;
  end
  else if (!game_set_wb3.stall_i && game_set_wb3.stb_o && !game_set_wb3.we_o) begin
    game_set_wb3.ack_i <= 1'b1;

    case (game_set_wb3.adr_o)
      ROW_COLUMN_NUMBER_ADDR: game_set_wb3.dat_i <= game_setup_mem [ROW_COLUMN_NUMBER_REG_NUM];
      MINE_NUM_ADDR:          game_set_wb3.dat_i <= game_setup_mem [MINE_NUM_REG_NUM];
      TIMER_SECONDS_ADDR:     game_set_wb3.dat_i <= game_setup_mem [TIMER_SECONDS_REG_NUM];
      FIELD_SIZE_ADDR:        game_set_wb3.dat_i <= game_setup_mem [FIELD_SIZE_REG_NUM];
      BOARD_SIZE_ADDR:        game_set_wb3.dat_i <= game_setup_mem [BOARD_SIZE_REG_NUM];
      BOARD_XPOS_ADDR:        game_set_wb3.dat_i <= game_setup_mem [BOARD_XPOS_REG_NUM];
      BOARD_YPOS_ADDR:        game_set_wb3.dat_i <= game_setup_mem [BOARD_YPOS_REG_NUM];
      GAMES_WON_ADDR:         game_set_wb3.dat_i <= game_setup_mem [GAMES_WON_REG_NUM];
      GAMES_LOST_ADDR:        game_set_wb3.dat_i <= game_setup_mem [GAMES_LOST_REG_NUM];
      default:                game_set_wb3.dat_i <= 16'hDEAD;
    endcase
  end
  else begin
    game_set_wb3.ack_i <= 1'b0;
    game_set_wb3.dat_i <= 16'b0;
  end
end


endmodule

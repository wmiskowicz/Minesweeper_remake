//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game. 
 */
//////////////////////////////////////////////////////////////////////////////
import game_pkg::*;

module main_fsm(
  input  wire  clk,  
  input  wire  rst,
  input  wire  [1:0] level,
  input  wire  timer_stop,
  input  wire  game_won,
  input  wire  game_lost,
  input  wire  retry,

  output logic [2:0] state_out,
  wishbone_if.slave game_settings
);

  localparam NUMBER_OF_REGISTERS = 9;

  localparam ROW_COLUMN_NUMBER_ADDR = 8'h00;
  localparam MINE_NUM_ADDR          = 8'h02;
  localparam TIMER_SECONDS_ADDR     = 8'h04;
  localparam FIELD_SIZE_ADDR        = 8'h08;
  localparam BOARD_SIZE_ADDR        = 8'h0A;
  localparam BOARD_XPOS_ADDR        = 8'h0C;
  localparam BOARD_YPOS_ADDR        = 8'h0E;
  localparam GAMES_WON_ADDR         = 8'h10;
  localparam GAMES_LOST_ADDR        = 8'h12;

  localparam ROW_COLUMN_NUMBER_REG_NUM = 0;
  localparam MINE_NUM_REG_NUM          = 1;
  localparam TIMER_SECONDS_REG_NUM     = 2;
  localparam FIELD_SIZE_REG_NUM        = 3;
  localparam BOARD_SIZE_REG_NUM        = 4;
  localparam BOARD_XPOS_REG_NUM        = 5;
  localparam BOARD_YPOS_REG_NUM        = 6;
  localparam GAMES_WON_REG_NUM         = 7;
  localparam GAMES_LOST_REG_NUM        = 8;

  // Local variables

  fsm_state_t state;
  logic [15:0] game_setup_mem [8:0];

    
  always_ff @(posedge clk) begin : fsm_blk
    if(rst)begin
      state <= MENU;
      state_out <= MENU;
      game_settings.stall_i <= 1'b1;
      for(int i=0; i < NUMBER_OF_REGISTERS; i++) game_setup_mem[i] <= 16'b0;
    end
    else begin
      state_out <= state;
      case(state)
        MENU: begin
          if(level > 0) begin 
            state <= PLAY;
            game_settings.stall_i <= 1'b1;
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
              default: for(int i=0; i < NUMBER_OF_REGISTERS; i++) game_setup_mem[i] <= 16'b0;

            endcase
          end
          else for(int i=0; i < NUMBER_OF_REGISTERS; i++) game_setup_mem[i] <= 16'b0;
        end
        PLAY: begin
          game_settings.stall_i <= 1'b0;
          if(timer_stop)     state <= PAUSE;
          else if(game_won)  state <= WIN; 
          else if(game_lost) state <= LOST; 
        end
        PAUSE: if(~timer_stop) state <= PLAY;
        WIN: begin
          game_setup_mem[GAMES_WON_REG_NUM]++;
          state <= GAME_OVER;
        end
        LOST: begin
          game_setup_mem[GAMES_LOST_REG_NUM]++;
          state <= GAME_OVER;
        end
        GAME_OVER: begin
          if(retry) state <= MENU;
        end
        default: state <= MENU;
      endcase  
    end
  end   
  
  
  always_ff @(posedge clk) begin
    if (!game_settings.stall_i && game_settings.stb_o && !game_settings.we_o) begin
      case (game_settings.adr_o)
        ROW_COLUMN_NUMBER_ADDR: game_settings.dat_i <= game_setup_mem [ROW_COLUMN_NUMBER_REG_NUM]; 
        MINE_NUM_ADDR:          game_settings.dat_i <= game_setup_mem [MINE_NUM_REG_NUM]; 
        TIMER_SECONDS_ADDR:     game_settings.dat_i <= game_setup_mem [TIMER_SECONDS_REG_NUM]; 
        FIELD_SIZE_ADDR:        game_settings.dat_i <= game_setup_mem [FIELD_SIZE_REG_NUM]; 
        BOARD_SIZE_ADDR:        game_settings.dat_i <= game_setup_mem [BOARD_SIZE_REG_NUM]; 
        BOARD_XPOS_ADDR:        game_settings.dat_i <= game_setup_mem [BOARD_XPOS_REG_NUM]; 
        BOARD_YPOS_ADDR:        game_settings.dat_i <= game_setup_mem [BOARD_YPOS_REG_NUM]; 
        GAMES_WON_ADDR:         game_settings.dat_i <= game_setup_mem [GAMES_WON_REG_NUM]; 
        GAMES_LOST_ADDR:        game_settings.dat_i <= game_setup_mem [GAMES_LOST_REG_NUM]; 
        default:                game_settings.dat_i <= 16'hDEAD;
      endcase
    end
  end

  assign game_settings.ack_i = !game_settings.stall_i && game_settings.stb_o;

    
endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game. 
 */
//////////////////////////////////////////////////////////////////////////////
module main_fsm(
  input  wire  clk,  
  input  wire  rst,
  input  wire  [1:0] level,
  input  wire  timer_stop,
  input  wire  game_won,
  input  wire  game_lost,
  input  wire  retry,
  output state_t state_out
);
  import game_pkg::*;

  // Local variables

  state_t state;
  game_setup_mem_t game_setup_mem;

    
  always_ff @(posedge clk) begin : fsm_blk
    if(rst)begin
      state <= MENU;
      state_out <= MENU;
      game_setup_mem <= '0;
    end
    else begin
      state_out <= state;
      case(state)
        MENU: begin
          if(level > 0) begin 
            state <= PLAY;
            case(level)
              2'd1: begin
                game_setup_mem.row_column_number <= E_ROW_COLUMN_NUMBER; 
                game_setup_mem.mine_number       <= E_MINE_NUM;
                game_setup_mem.timer_seconds     <= E_TIMER_SECONDS; 
                game_setup_mem.field_size        <= E_FIELD_SIZE;
                game_setup_mem.board_size        <= E_BOARD_SIZE;
                game_setup_mem.board_xpos        <= E_BOARD_XPOS;
                game_setup_mem.board_ypos        <= E_BOARD_YPOS;
              end
              2'd2: begin
                game_setup_mem.row_column_number <= M_ROW_COLUMN_NUMBER; 
                game_setup_mem.mine_number       <= M_MINE_NUM;
                game_setup_mem.timer_seconds     <= M_TIMER_SECONDS; 
                game_setup_mem.field_size        <= M_FIELD_SIZE;
                game_setup_mem.board_size        <= M_BOARD_SIZE;
                game_setup_mem.board_xpos        <= M_BOARD_XPOS;
                game_setup_mem.board_ypos        <= M_BOARD_YPOS;
              end
              2'd3: begin
                game_setup_mem.row_column_number <= H_ROW_COLUMN_NUMBER; 
                game_setup_mem.mine_number       <= H_MINE_NUM;
                game_setup_mem.timer_seconds     <= H_TIMER_SECONDS; 
                game_setup_mem.field_size        <= H_FIELD_SIZE;
                game_setup_mem.board_size        <= H_BOARD_SIZE;
                game_setup_mem.board_xpos        <= H_BOARD_XPOS;
                game_setup_mem.board_ypos        <= H_BOARD_YPOS;
              end
              default: game_setup_mem <= '0;
            endcase
          end
          else begin
            game_setup_mem.row_column_number <= '0; 
            game_setup_mem.mine_number       <= '0;
            game_setup_mem.timer_seconds     <= '0; 
            game_setup_mem.field_size        <= '0;
            game_setup_mem.board_size        <= '0;
            game_setup_mem.board_xpos        <= '0;
            game_setup_mem.board_ypos        <= '0;
          end
        end
        PLAY: begin
          if(timer_stop)     state <= PAUSE;
          else if(game_won)  state <= WIN; 
          else if(game_lost) state <= LOST; 
        end
        PAUSE: if(~timer_stop) state <= PLAY;
        WIN: begin
          game_setup_mem.games_won++;
          state <= GAME_OVER;
        end
        LOST: begin
          game_setup_mem.games_lost++;
          state <= GAME_OVER;
        end
        GAME_OVER: begin
          if(retry) state <= MENU;
        end
        default: state <= MENU;
      endcase  
    end
  end      
    
endmodule

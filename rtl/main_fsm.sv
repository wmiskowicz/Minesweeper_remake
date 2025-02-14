`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm.sv
 Author:        Wojciech Miskowicz
 Description:   Module containing the FSM controlling the game. 
 */
//////////////////////////////////////////////////////////////////////////////
 module main_fsm
    (
        input  wire  clk,  
        input  wire  rst
    );


    typedef enum{MENU, NEW_GAME, PAUSE, PLAY, FAIL, WIN, GAME_OVER} state_t;

    state_t state;
    
    always_ff @(posedge clk) begin : state_seq_blk
      if(rst)begin
        state <= MENU;
      end
      else begin
        case(state)
          MENU: begin end

        endcase  
      end
    end      
    
    endmodule
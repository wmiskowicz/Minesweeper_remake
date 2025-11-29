//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   defuser.sv
 Author:        Wojciech Miskowicz
 Description:   Module for implementing Minesweeper defuse algorithm.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../memory/wishbone_defs.svh"
`include "defuser.svh"

import game_pkg::*;

module defuser (
  input wire clk,
  input wire rst,

  input wire planting_complete,
  input wire [2:0] main_state,

  input logic [11:0] mouse_xpos,
  input logic [11:0] mouse_ypos,

  input wire left,
  input wire right,

  output logic pause,
  output logic back_to_menu,
  output logic retry,
  output logic game_lost,
  output logic game_won,

  wishbone_if.master game_set_wb,
  wishbone_if.master game_board_wb
);

// ----- Local parameters -----
localparam SETTINGS_REG_NUM = 9;
localparam HALF_FRAME_CYCLES = 618750;
localparam int BTM_RETRY_HOLD_CYCLES = 100;



// ----- Local variables -----
field_t game_board_mem [15:0][15:0];
logic [15:0] game_setup_cashe [SETTINGS_REG_NUM-1:0];

logic burst_active;
logic [15:0] read_data;
logic [7:0] read_addr;
logic [3:0] settings_read_ctr;
logic read_en;
logic read_ready;

logic [8:0]  game_write_addr;
logic [15:0] game_write_data;
logic game_write_en;
logic game_write_ready;
logic game_burst_write;
logic game_burst_read;
logic game_burst_active;

logic [8:0]  game_read_addr;
logic [15:0] game_read_data;
logic game_read_en;
logic game_read_ready;

logic mouse_xpos_valid;
logic mouse_ypos_valid;

logic left_q, right_q;

logic [11:0] mouse_board_xpos;
logic [11:0] mouse_board_ypos;

logic [3:0] mouse_board_ind_x;
logic [3:0] mouse_board_ind_y;

logic [19:0] timing_ctr;
logic board_ready;
logic game_won_p;

logic [3:0] mine_ind;

logic [3:0] col_ctr;
logic [3:0] row_ctr;
logic count_en;
logic redo_defuse;

logic pause_q;
logic retry_q;
logic btm_q;
logic [7:0] btm_ctr;
logic [7:0] retry_ctr;


auto_write_state_t auto_write_state;
auto_read_state_t auto_read_state;
defuser_state_t defuser_state;


// ----- Signal assignments -----
assign mouse_ypos_valid = mouse_ypos >= game_setup_cashe[BOARD_YPOS_REG_NUM] && mouse_ypos < (game_setup_cashe[BOARD_YPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM]);
assign mouse_xpos_valid = mouse_xpos >= game_setup_cashe[BOARD_XPOS_REG_NUM] && mouse_xpos < (game_setup_cashe[BOARD_XPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM]);

assign mouse_board_ypos = mouse_ypos_valid && mouse_xpos_valid ? mouse_ypos - game_setup_cashe[BOARD_YPOS_REG_NUM] : 12'hFFF;
assign mouse_board_xpos = mouse_ypos_valid && mouse_xpos_valid ? mouse_xpos - game_setup_cashe[BOARD_XPOS_REG_NUM] : 12'hFFF;

assign mouse_board_ind_x = mouse_board_xpos[9:6];
assign mouse_board_ind_y = mouse_board_ypos[9:6];

assign game_burst_active = game_burst_write || game_burst_read;
assign game_write_data = {8'b0, game_board_mem[game_write_addr[7:4]][game_write_addr[3:0]]};

assign back_to_menu = btm_q;
assign pause = pause_q;
assign retry = retry_q;

// Pause, resume and back_to_menu logic 
always_ff @(posedge clk) begin
  if (rst) begin
    pause_q <= 1'b0;
    btm_q   <= 1'b0;
    btm_ctr <= 8'd0;
  end
  else begin
    if (mouse_xpos >= game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd64 &&
        mouse_xpos <  game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd96 &&
        mouse_ypos >= game_setup_cashe[BOARD_YPOS_REG_NUM] - 15'd32 &&
        mouse_ypos <  game_setup_cashe[BOARD_YPOS_REG_NUM] && left) 
    begin
      pause_q <= 1'b0;
      btm_ctr <= 8'd0;
      btm_q   <= 1'b1;
    end
    else if (mouse_xpos >= game_setup_cashe[BOARD_XPOS_REG_NUM] &&
             mouse_xpos <  game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd32 &&
             mouse_ypos >= game_setup_cashe[BOARD_YPOS_REG_NUM] - 15'd32 &&
             mouse_ypos <  game_setup_cashe[BOARD_YPOS_REG_NUM] && left)
    begin
      pause_q <= (main_state == PAUSE || main_state == PLAY) ? !pause_q : pause_q;
    end   
    else if (btm_q) begin
      if (btm_ctr >= BTM_RETRY_HOLD_CYCLES) begin
        btm_q <= 1'b0;
        btm_ctr <= 1'b0;
      end
      else begin
        btm_ctr <= btm_ctr + 8'd1;
      end
    end
  end
end

// retry logic
always_ff @(posedge clk) begin
  if (rst) begin
    retry_q <= 1'b0;
    retry_ctr <= 8'd0;
  end
  else begin
    if (mouse_xpos >= game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd32 &&
        mouse_xpos <  game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd64 &&
        mouse_ypos >= game_setup_cashe[BOARD_YPOS_REG_NUM] - 15'd32 &&
        mouse_ypos <  game_setup_cashe[BOARD_YPOS_REG_NUM] && left) 
    begin
      retry_ctr <= 8'd0;
      retry_q   <= 1'b1;
    end 
    else if (retry_q) begin
      if (retry_ctr >= BTM_RETRY_HOLD_CYCLES) begin
        retry_q <= 1'b0;
        retry_ctr <= 1'b0;
      end
      else begin
        retry_ctr <= retry_ctr + 8'd1;
      end
    end
  end
end


// Auto read logic
always_ff @(posedge clk) begin
  if (rst) begin
    auto_read_state <= AR_IDLE;

    burst_active <= 1'b0;
    read_addr    <= 8'b0;
    settings_read_ctr <= 4'b0;
    read_en           <= 1'b0;
    

    game_burst_read   <= 1'b0;
    game_read_addr    <= 9'h00;
    game_read_en      <= 1'b0;

    board_ready       <= 1'b0;
  end
  else begin
    case(auto_read_state)
      AR_IDLE: begin
        burst_active    <= 1'b0;
        auto_read_state <= planting_complete ? AR_READ_SETTINGS : AR_IDLE;
        read_en         <= planting_complete;
        read_addr       <= 8'h0;

        game_burst_read <= 1'b0;
        game_read_addr  <= 9'h00;
        game_read_en    <= 1'b0;

        board_ready       <= 1'b0;
        settings_read_ctr <= 4'b0;
      end
      AR_READ_SETTINGS: begin
        burst_active <= 1'b1;
        read_en <= 1'b0;

        if (settings_read_ctr == SETTINGS_REG_NUM && !game_burst_write) begin
          auto_read_state <= AR_READ_BOARD;
          game_burst_read <= 1'b1;
          game_read_en    <= 1'b1;
          game_read_addr  <= 9'h00;
        end

        if (read_ready && settings_read_ctr < SETTINGS_REG_NUM) begin

          game_setup_cashe[settings_read_ctr] <= read_data;
          settings_read_ctr <= settings_read_ctr + 1;

          read_addr <= (settings_read_ctr + 1) * 8'h2;
          read_en   <= 1'b1;
        end
      end
      AR_READ_BOARD: begin
        game_read_en <= 1'b0;

        if (game_read_ready) begin
          game_read_addr <= game_read_addr + 9'd1;
          game_read_en   <= 1'b1;
        end

        if (game_read_addr == 9'h100) begin
          game_read_en    <= 1'b0;
          game_burst_read <= 1'b0;
          auto_read_state <= AR_DONE;
          board_ready     <= 1'b1;
        end
      end
      AR_DONE: auto_read_state <= (retry_q || (main_state == MENU)) ? AR_IDLE : AR_DONE;
      default: auto_read_state <= AR_IDLE;
    endcase
  end
end

// Auto write logic
always_ff @(posedge clk) begin
  if (rst || btm_q) begin
    timing_ctr <= 20'b0;
    auto_write_state <= AW_WAIT;

    game_write_en    <= 1'b0;
    game_burst_write <= 1'b0;
    game_write_addr  <= 9'h0;
  end
  else begin
    case (auto_write_state)
      AW_WAIT: begin
        if (timing_ctr == HALF_FRAME_CYCLES) begin
          if (!game_burst_read) begin
            auto_write_state <= AW_WRITE;
            timing_ctr       <= 20'b0;

            game_burst_write <= 1'b1;
            game_write_en    <= 1'b1;
            game_write_addr  <= 9'h0;
          end

        end
        else timing_ctr <= timing_ctr + 20'd1;
      end
      AW_WRITE: begin
        game_write_en   <= 1'b0;

        if (game_write_ready) begin
          game_write_addr <= game_write_addr + 9'd1;
          game_write_en   <= 1'b1;
        end

        if (game_write_addr == 9'h100) begin
          game_write_en     <= 1'b0;
          game_burst_write  <= 1'b0;
          auto_write_state  <= AW_WAIT;
        end
      end
      default: auto_write_state <= AW_WAIT;
    endcase
  end
end


// Defuse logic
always_ff @(posedge clk) begin
  if (rst || btm_q) begin
    col_ctr <= 4'b0;
    row_ctr <= 4'b0;
  end
  else if (count_en) begin
    if(row_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1) begin
      row_ctr <= 4'h0;

      if (col_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1) begin
        col_ctr <= 4'd0;
      end
      else begin
        col_ctr <= col_ctr + 4'd1;
      end
    end
    else begin
      row_ctr <= row_ctr + 4'd1;
    end
  end
  else begin
    col_ctr <= 4'b0;
    row_ctr <= 4'b0;
  end
end

always_ff @(posedge clk) begin
  if (rst || btm_q || retry) begin
    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)  
        game_board_mem[i][j] <= 8'b0;

    defuser_state <= DEF_IDLE;
    count_en      <= 1'b0;
    redo_defuse   <= 1'b0;
    game_won_p    <= 1'b0;

    game_lost <= 1'b0;
    game_won  <= 1'b0;
    mine_ind  <= 4'h0;
    left_q    <= 1'b0;
    right_q   <= 1'b0;
  end
  else begin
    left_q    <= main_state == PAUSE  || main_state == GAME_OVER ? 1'b0 : left;
    right_q   <= main_state == PAUSE  || main_state == GAME_OVER ? 1'b0 : right;

    case (defuser_state)
      DEF_IDLE: begin
        
      for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++)  
          game_board_mem[i][j] <= 8'b0;

        // defuser_state <= main_state == PLAY ? DEF_READ_BOARD : DEF_IDLE;
        defuser_state <= main_state == PLAY && planting_complete ? DEF_READ_BOARD : DEF_IDLE;
        count_en    <= 1'b0;
        redo_defuse <= 1'b0;

        game_lost  <= 1'b0;
        game_won   <= 1'b0;
        game_won_p <= 1'b0;
        mine_ind   <= 4'h0;
      end

      DEF_READ_BOARD: begin
        if (game_read_ready)
          game_board_mem[game_read_addr[7:4]][game_read_addr[3:0]] <= field_t'(game_read_data[7:0]);

        defuser_state <= board_ready ? DEF_WRITE_MINE_IND : DEF_READ_BOARD;
      end

      DEF_WRITE_MINE_IND: begin
        count_en <= 1'b1;
        for (int dy = -1; dy <= 1; dy++) begin
          for (int dx = -1; dx <= 1; dx++) begin

            if ((dx == 0) && (dy == 0))
              continue;

            if ((row_ctr+dy >= 0) && (row_ctr+dy < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) &&
                (col_ctr+dx >= 0) && (col_ctr+dx < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) &&
                game_board_mem[row_ctr+dy][col_ctr+dx].mine) begin


              mine_ind++;
            end
          end
        end

        game_board_mem[row_ctr][col_ctr].mine_ind <= mine_ind;
        mine_ind <= 4'h0;

        defuser_state <= (row_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1 &&
                          col_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1) ? DEF_WAIT_FOR_MOUSE : DEF_WRITE_MINE_IND;
      end

      DEF_WAIT_FOR_MOUSE: begin
        count_en <= 1'b0;
        if (mouse_xpos_valid && mouse_ypos_valid && left_q) begin

          game_board_mem[mouse_board_ind_y][mouse_board_ind_x].defused <= 1'b1;

          if (game_board_mem[mouse_board_ind_y][mouse_board_ind_x].mine) begin
            game_lost     <= 1'b1;
            defuser_state <= DEF_GAME_OVER;
          end
          else begin
            defuser_state <= DEFUSE;
          end
        end
        else if (mouse_xpos_valid && mouse_ypos_valid && right_q) begin
          game_board_mem[mouse_board_ind_y][mouse_board_ind_x].flag <= !game_board_mem[mouse_board_ind_y][mouse_board_ind_x].flag;
          defuser_state <= DEFUSE;
        end
      end

      DEFUSE: begin
        count_en <= 1'b1;
        if (game_board_mem[row_ctr][col_ctr].mine_ind == 0 && game_board_mem[row_ctr][col_ctr].defused) begin

          for (int dy = -1; dy <= 1; dy++) begin
            for (int dx = -1; dx <= 1; dx++) begin

              if ((dx == 0) && (dy == 0))
                continue;

              if ((row_ctr+dy >= 0) && (row_ctr+dy < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) &&
                  (col_ctr+dx >= 0) && (col_ctr+dx < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM])) begin

                if (game_board_mem[row_ctr+dy][col_ctr+dx].mine == 1'b0 &&
                    game_board_mem[row_ctr+dy][col_ctr+dx].flag == 1'b0 &&
                    game_board_mem[row_ctr+dy][col_ctr+dx].defused == 1'b0
                  ) begin

                  game_board_mem[row_ctr+dy][col_ctr+dx].defused <= 1'b1;
                end

              end
            end
          end
        end

        if (row_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1 &&
          col_ctr == game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]-1) begin
            defuser_state <= DEF_INSPECT_BOARD;
            count_en <= 1'b0;

            // by default presume board defused and game won
            game_won_p  <= 1'b1;
            redo_defuse <= 1'b0;
        end
        else begin
            defuser_state <= DEFUSE;
        end

      end

      DEF_INSPECT_BOARD: begin

        for (int i = 0; i < 16; i++) begin
          for (int j = 0; j < 16; j++) begin
            if(i < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM] && j < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) begin

              // Check if game won
              if(!(game_board_mem[i][j].defused || (game_board_mem[i][j].mine && game_board_mem[i][j].flag))) begin
                game_won_p <= 1'b0;
              end

              // Check if everything is defused
              for (int dy = -1; dy <= 1; dy++) begin
                for (int dx = -1; dx <= 1; dx++) begin

                  if ((i+dx >= 0) && (i+dx < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) &&
                  (j+dy >= 0) && (j+dy < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM])) begin

                    if ((dx == 0) && (dy == 0))
                      continue;

                    if (game_board_mem[i][j].defused == 1'b1 && 
                        game_board_mem[i][j].mine_ind == 0 &&
                        !(game_board_mem[i+dx][j+dy].defused)
                      ) begin
                      redo_defuse <= 1'b1;
                    end
                  end

                end
              end
            end
          end
        end

        defuser_state <= DEF_WIN_CHECK;
      end

      DEF_WIN_CHECK: begin
        count_en    <= 1'b0;
        redo_defuse <= 1'b0;

        if (game_won_p) begin
          defuser_state <= DEF_GAME_OVER;
          game_won <= 1'b1;
        end
        else if (redo_defuse)
          defuser_state <= DEFUSE;
        else
          defuser_state <= DEF_WAIT_FOR_MOUSE;
      end

      DEF_GAME_OVER: defuser_state <= main_state == MENU ? DEF_IDLE : DEF_GAME_OVER;


      default: defuser_state <= DEF_IDLE;
    endcase
  end
end

wishbone_master u_settings_master (
  .clk         (clk),
  .rst         (rst),

  .burst_active(burst_active),
  .read_addr   (read_addr),
  .read_data   (read_data),
  .read_en     (read_en),
  .read_ready  (read_ready),

  .wb_master   (game_set_wb),

  .write_addr  ('0),
  .write_data  ('0),
  .write_en    ('0),
  .write_ready ()
);

wishbone_master u_board_master (
  .clk         (clk),
  .rst         (rst),

  .read_addr   (game_read_addr[7:0]),
  .read_data   (game_read_data),
  .read_en     (game_read_en),
  .read_ready  (game_read_ready),
  .burst_active(game_burst_active),

  .write_addr  (game_write_addr[7:0]),
  .write_data  (game_write_data),
  .write_en    (game_write_en),
  .write_ready (game_write_ready),

  .wb_master   (game_board_wb)
);


endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   defuser.sv
 Author:        Wojciech Miskowicz
 Description:   Module for implementing Minesweeper defuse algorithm.
 */
//////////////////////////////////////////////////////////////////////////////
import game_pkg::*;

module defuser (
    input wire clk,
    input wire rst,

    input wire planting_complete,

    input logic [11:0] mouse_xpos,
    input logic [11:0] mouse_ypos,

    input logic left,
    input logic right,

    wishbone_if.master game_set_wb,
    wishbone_if.master game_board_wb
  );

  localparam SETTINGS_REG_NUM = 9;


  enum logic [2:0] {
    IDLE,
    READ_SETTINGS,
    READ_BOARD,
    DEFUSE
  } defuser_state;

  typedef struct packed {
    logic mined;
    logic defused;
  } cell_flags_t;


  (* ram_style = "block" *)
  field_t game_board_mem [15:0][15:0];
  logic [15:0] game_setup_cashe [SETTINGS_REG_NUM-1:0];

  logic burst_active;
  logic [15:0] read_data;
  logic [7:0] read_addr;
  logic [3:0] settings_read_ctr;
  logic read_en;
  logic read_ready;

  logic [7:0]  game_write_addr;
  logic [15:0] game_write_data;
  logic game_write_en;
  logic game_write_ready;
  logic game_burst_active;

  logic [7:0]  game_read_addr;
  logic [15:0] game_read_data;
  logic game_read_en;
  logic game_read_ready;

  logic mouse_xpos_valid;
  logic mouse_ypos_valid;

  logic [4:0] mouse_board_ind_x;
  logic [4:0] mouse_board_ind_y;


  assign mouse_ypos_valid = mouse_ypos >= game_setup_cashe[BOARD_XPOS_REG_NUM] && mouse_ypos < game_setup_cashe[BOARD_XPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM];
  assign mouse_xpos_valid = mouse_xpos >= game_setup_cashe[BOARD_XPOS_REG_NUM] && mouse_xpos < game_setup_cashe[BOARD_XPOS_REG_NUM] + game_setup_cashe[BOARD_SIZE_REG_NUM];

  assign mouse_board_ind_y = mouse_ypos_valid && mouse_xpos_valid ? mouse_ypos - game_setup_cashe[BOARD_XPOS_REG_NUM] : 5'h1_f;
  assign mouse_board_ind_x = mouse_ypos_valid && mouse_xpos_valid ? mouse_xpos - game_setup_cashe[BOARD_XPOS_REG_NUM] : 5'h1_f;



  always_ff @(posedge clk) begin
    if(rst)begin
      defuser_state <= IDLE;

      burst_active <= 1'b0;
      read_addr    <= 8'b0;
      settings_read_ctr <= 4'b0;
      read_en <= 1'b0;
    end
    else begin
      case(defuser_state)
        IDLE: begin
          burst_active <= 1'b0;
          defuser_state <= planting_complete ? READ_SETTINGS : IDLE;
          read_en <= planting_complete;
          read_addr <= 8'h0;
        end
        READ_SETTINGS: begin
          burst_active <= 1'b1;
          read_en <= 1'b0;
          
          if (settings_read_ctr == SETTINGS_REG_NUM) begin
            defuser_state <= READ_BOARD;
            game_burst_active <= 1'b1;
            game_read_en      <= 1'b1;
            game_read_addr    <= 8'h00;
          end

          if (read_ready && settings_read_ctr < SETTINGS_REG_NUM) begin
            game_setup_cashe[settings_read_ctr] <= read_data;
            settings_read_ctr <= settings_read_ctr + 1;
            read_addr <= (settings_read_ctr + 1) * 8'h2;
            read_en <= 1'b1;
          end
        end
        READ_BOARD: begin      
          game_read_en <= 1'b0;
      
          if (game_read_ready) begin
            game_board_mem[game_read_addr[7:4]][game_read_addr[3:0]] <= game_read_data[7:0];
            game_read_addr <= game_read_addr + 8'd2;
            game_read_en   <= 1'b1;
          end
      
          if (game_read_addr == 8'hFE) begin
            game_read_en       <= 1'b0;
            game_burst_active  <= 1'b0;
            defuser_state      <= IDLE;
          end
        end
        default: defuser_state <= IDLE;
      endcase
    end
  end

  // Auto write logic
  // TODO


  // Defuse logic 
  logic [3:0] col_ctr;
  logic [3:0] row_ctr;

  always_ff @(posedge clk) begin
    if (rst) begin
      col_ctr <= 4'b0;
      row_ctr <= 4'b0;
    end
    else begin
      col_ctr <= col_ctr + 1;
      if (row_ctr == 4'hF) row_ctr <= row_ctr + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++)  game_board_mem[i][j] <= 8'b0;
    end
    else begin
      if (mouse_ypos_valid && mouse_ypos_valid) begin
        if (left)  game_board_mem[mouse_board_ind_y][mouse_board_ind_x].defused <= 1'b1;
        if (right) game_board_mem[mouse_board_ind_y][mouse_board_ind_x].flag <= !game_board_mem[mouse_board_ind_y][mouse_board_ind_x].flag;
      end

      if (game_board_mem[row_ctr][col_ctr].mine_ind == 0) begin

        for (int dy = -1; dy <= 1; dy++) begin
          for (int dx = -1; dx <= 1; dx++) begin

            if ((dx == 0) && (dy == 0))
              continue;

            if ((row_ctr+dy >= 0) && (row_ctr+dy < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]) &&
                (col_ctr+dx >= 0) && (col_ctr+dx < game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM])) begin

              if (game_board_mem[row_ctr+dy][col_ctr+dx].mine == 1'b0 &&
                  game_board_mem[row_ctr+dy][col_ctr+dx].defused == 1'b0) begin

                game_board_mem[row_ctr+dy][col_ctr+dx].defused <= 1'b1;
              end
            end
          end
        end
      end  end
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

    .read_addr   (game_read_addr),
    .read_data   (game_read_data),
    .read_en     (game_read_en),
    .read_ready  (game_read_ready),
    .burst_active(game_burst_active),

    .write_addr  (game_write_addr),
    .write_data  (game_write_data),
    .write_en    ('0),//(game_write_en),
    .write_ready (game_write_ready),

    .wb_master   (game_board_wb)
  );


endmodule

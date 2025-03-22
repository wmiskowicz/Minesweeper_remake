//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   mine_planter.sv
 Author:        Wojciech Miskowicz
 Description:   Module responsible for random mine distribution on the board.
 */
//////////////////////////////////////////////////////////////////////////////
import game_pkg::*;

module mine_planter (
    input wire clk,
    input wire rst,

    input logic [2:0] main_state,

    wishbone_if.master game_set_wb,
    wishbone_if.master game_board_wb
  );

  (* ram_style = "block" *)
  logic mine_map[15:0][15:0];
  logic current_field_mine;

  logic [15:0] counter;
  logic [15:0] row_col_num;
  logic [15:0] mines_left;

  logic [3:0]  din_x, din_y;
  logic [3:0]  ind_x, ind_y;

  logic settings_burst_active;
  logic settings_read_en;
  logic settings_read_ready;
  logic [15:0] settings_read_data;
  logic [7:0]  settings_read_addr;

  logic [7:0]  game_write_addr;
  logic [15:0] game_write_data;
  logic game_write_en;
  logic game_write_ready;
  logic game_burst_active;

  enum logic [2:0] {
    IDLE,
    READ_SETTINGS,
    PLANT,
    WRITE_BOARD,
    DONE
  } planter_state;

  assign current_field_mine = mine_map[game_write_addr[7:4]][game_write_addr[3:0]];
  assign game_write_data = {8'b0, current_field_mine, 7'b0};

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++)  mine_map[i][j] <= 1'b0;

      planter_state <= IDLE;

      settings_burst_active <= 1'b0;
      settings_read_en <= 1'b0;
      settings_read_addr <= 8'b0;
      row_col_num <= 16'b1;
      mines_left  <= 16'b0;

      game_burst_active <= 1'b0;
      game_write_addr   <= 8'h0;
    end
    else begin
      case (planter_state)
        IDLE: begin
          if (main_state == PLAY) begin
            planter_state <= READ_SETTINGS;
            settings_read_en <= 1'b1;
            settings_burst_active <= 1'b1;
          end

          for (int i = 0; i < 16; i++)
            for (int j = 0; j < 16; j++)  mine_map[i][j] <= 1'b0;

          settings_read_addr <= 8'b0;
          game_write_addr   <= 8'h0;
          row_col_num <= 16'b1;
        end
        READ_SETTINGS: begin
          settings_read_en <= 1'b0;

          if (settings_read_ready && settings_read_addr < 8'd4) begin

            if (settings_read_addr == 0) row_col_num <= settings_read_data;
            else mines_left  <= settings_read_data;

            settings_read_addr <= settings_read_addr + 8'd2;
            settings_read_en <= 1'b1;

            if (settings_read_addr == 8'd2) begin
              planter_state <= PLANT;
              settings_burst_active <= 1'b0;
            end
          end
        end
        PLANT: begin
          if (mines_left > 0) begin
            if (!mine_map[ind_x][ind_y]) begin
              mine_map[ind_x][ind_y] <= 1'b1;
              mines_left <= mines_left - 15'd1;
            end
          end
          else begin
            planter_state <= WRITE_BOARD;
            game_burst_active <= 1'b1;
            game_write_en     <= 1'b1;
            game_write_addr   <= 8'h0;
          end
        end
        WRITE_BOARD: begin
          game_write_en   <= 1'b0;

          if (game_write_ready) begin
            game_write_addr <= game_write_addr + 8'd2;
            game_write_en   <= 1'b1;
          end

          if (game_write_addr == 8'hFE) begin
            game_write_en   <= 1'b0;
            game_burst_active <= 1'b0;
            planter_state <= DONE;
          end
        end
        DONE: planter_state <= main_state == GAME_OVER ? IDLE : DONE; 
        default: planter_state <= IDLE;
      endcase
    end
  end


  // Pseudo random number generation
  logic [17:0] din0, dout0;
  logic [16:0] din1, dout1;
  logic [15:0] din2, dout2;
  logic signed [18:0] dout=0;

  lfsr #(.WIDTH(18)) lfsr0 (.datain(din0), .dataout(dout0));
  lfsr #(.WIDTH(17)) lfsr1 (.datain(din1), .dataout(dout1));
  lfsr #(.WIDTH(16)) lfsr2 (.datain(din2), .dataout(dout2));

  assign ind_x = dout[18:15] % row_col_num;
  assign ind_y = dout[7:4] % row_col_num;


  always_ff @(posedge clk) begin
    if (rst) begin
      din0 <= 18'b1;
      din1 <= 17'b1;
      din2 <= 16'b1;
      dout <= 19'b0;
    end
    else begin
      din0 <= dout0;
      din1 <= dout1;
      din2 <= dout2;
      dout <= din0[17:0] + din1[16:0] + din2[15:0];
    end
  end




  wishbone_master u_settings_master (
    .clk         (clk),
    .rst         (rst),

    .read_addr   (settings_read_addr),
    .read_data   (settings_read_data),
    .read_en     (settings_read_en),
    .read_ready  (settings_read_ready),
    .burst_active(settings_burst_active),

    .write_addr  ('0),
    .write_data  ('0),
    .write_en    ('0),
    .write_ready (),

    .wb_master   (game_set_wb)
  );

  wishbone_master u_board_master (
    .clk         (clk),
    .rst         (rst),

    .read_addr   ('0),
    .read_data   (),
    .read_en     ('0),
    .read_ready  (),
    .burst_active(game_burst_active),

    .write_addr  (game_write_addr),
    .write_data  (game_write_data),
    .write_en    (game_write_en),
    .write_ready (game_write_ready),

    .wb_master   (game_board_wb)
  );


endmodule

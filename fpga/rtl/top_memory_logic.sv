 module top_memory_logic (
     input  wire       clk100MHz,
     input  wire       clk74MHz,
     input  wire       rst,

     input  wire [1:0] level,
 
     inout  wire       PS2Clk,
     inout  wire       PS2Data,
 
     output wire       planting_complete,

 
     output wire       Vsync,
     output wire       Hsync,
     output wire [3:0] vgaRed,    
     output wire [3:0] vgaGreen,
     output wire [3:0] vgaBlue,
 
     output wire [3:0] mouse_board_ind_x,
     output wire [3:0] mouse_board_ind_y,

     output logic mouse_xpos_valid,
     output logic mouse_ypos_valid
 );
 
 
 /**
  * Local variables and signals
  */
 wire [2:0] main_state;
 
 wire [11:0] mouse_xpos;
 wire [11:0] mouse_ypos;
 
 wire left;
 wire right;
 wire game_lost;
 wire game_won;
 
 
 
 wishbone_if planter_set_wb_if();
 wishbone_if planter_board_wb_if();
 
 wishbone_if defuser_set_wb_if();
 wishbone_if defuser_board_wb_if();
 
 wishbone_if vga_board_wb_if();
 wishbone_if vga_set_wb_if();
 
 
 /**
  * Submodules placement
  */
 
 top_vga u_top_vga (
     .clk          (clk74MHz),
     .rst          (rst),
     .r            (vgaRed),
     .g            (vgaGreen),
     .b            (vgaBlue),
     .hs           (Hsync),
     .vs           (Vsync),
 
     .mouse_xpos   (mouse_xpos),
     .mouse_ypos   (mouse_ypos),
     .main_state   (main_state),
 
     .game_settings_wb(vga_set_wb_if.master),
     .game_board_wb   (vga_board_wb_if.master)
 
 );
 
 top_mouse u_top_mouse (
   .clk100MHz  (clk100MHz),
   .clk74MHz   (clk74MHz),
   .rst       (rst),
   .ps2_clk   (PS2Clk),
   .ps2_data  (PS2Data),
 
   .left      (left),
   .right     (right),
   .mouse_xpos(mouse_xpos),
   .mouse_ypos(mouse_ypos)
 );
 
 top_memory u_top_memory (
   .clk74MHz (clk74MHz),
   .rst      (rst),
 
   .read_wb  (vga_board_wb_if.slave),
   .write1_wb(planter_board_wb_if.slave),
   .write2_wb(defuser_board_wb_if.slave)
 );
 
 defuser u_defuser (
   .clk              (clk74MHz),
   .rst              (rst),
 
   .planting_complete(planting_complete),
   .main_state       (main_state),
 
   .mouse_xpos       (mouse_xpos),
   .mouse_ypos       (mouse_ypos),
 
   .mouse_board_ind_x(mouse_board_ind_x),
   .mouse_board_ind_y(mouse_board_ind_y),
 
   .mouse_xpos_valid(mouse_xpos_valid),
   .mouse_ypos_valid(mouse_ypos_valid),  
 
   .left             (left),
   .right            (right),
 
   .game_lost        (game_lost),
   .game_won         (game_won),
 
   .game_board_wb    (defuser_board_wb_if.master),
   .game_set_wb      (defuser_set_wb_if.master)
 );
 
 
 mine_planter u_mine_planter (
   .clk          (clk74MHz),
   .rst          (rst),
 
   .main_state   (main_state),
   .planting_complete(planting_complete),
   .game_board_wb(planter_board_wb_if.master),
   .game_set_wb  (planter_set_wb_if.master)
 );

 
 
 main_fsm u_main_fsm (
   .clk       (clk74MHz),
   .rst       (rst),
   .level     (level),
 
   .game_lost (game_lost),
   .game_won  (game_won),
   .retry     (1'b0),
   .timer_stop(1'b0),
 
   .state_out(main_state),
 
   .game_set_wb1(planter_set_wb_if.slave),
   .game_set_wb2(defuser_set_wb_if.slave),
   .game_set_wb3(vga_set_wb_if.slave)
 );
 
 
 endmodule
 
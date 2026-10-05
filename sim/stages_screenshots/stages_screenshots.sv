//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   stages_screenshots.sv
 Author:        Wojciech Miskowicz
 Description:   Plays the full top level design through its game stages and
                saves one 1280x720 VGA frame of each (menu, gameplay, game
                over) to results/screenshots/ using tiff_writer.
                Mouse position and clicks are forced on the top level nets,
                and the planted mine map is read from the hierarchy, so the
                testbench always knows which field is safe to open.
 */
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`include "../../XVunit/internals/verilog/xvunit_defines.svh"


module stages_screenshots;

import vga_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 10ns;
localparam string SHOT_DIR = "../../results/screenshots";

localparam int SHOT_MENU      = 0;
localparam int SHOT_GAMEPLAY  = 1;
localparam int SHOT_GAME_OVER = 2;

// Middle of the "Medium" button, see level_select.sv
localparam logic [11:0] MENU_MEDIUM_X = 12'd638;
localparam logic [11:0] MENU_MEDIUM_Y = 12'd438;

localparam int FIELD_SIZE = 64;
localparam int MAX_FLAGS  = 3;


// ----- Local variables -----
logic clk;
logic rst;

logic [4:0] led;
wire        locked = led[0];
wire        PS2Clk;
wire        PS2Data;
wire        Vsync, Hsync;
wire  [3:0] vgaRed, vgaGreen, vgaBlue;
wire  [6:0] seg;
wire  [3:0] an;
wire        dp;

// Frame capture
wire        pix_clk = dut.clk74MHz;
logic [2:0] go;

// Mouse
logic [11:0] mouse_x;
logic [11:0] mouse_y;
logic       cap_clk;
logic       capturing;
logic [11:0] cap_rgb;
int          cap_pixels;
int          cap_lit_pixels;
int          cap_colour_changes;
logic [11:0] cap_prev_rgb;


// ----- PS/2 lines -----
// No mouse is attached: the lines idle high like the board pull-ups,
// and the DUT may still pull them low. Mouse input is forced below.
assign PS2Clk  = (dut.u_top_mouse.u_MouseCtl.Inst_Ps2Interface.ps2_clk_h  === 1'b0) ? 1'bz : 1'b1;
assign PS2Data = (dut.u_top_mouse.u_MouseCtl.Inst_Ps2Interface.ps2_data_h === 1'b0) ? 1'bz : 1'b1;


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end


top_basys3 dut (
  .clk      (clk),
  .btnD     (rst),
  .PS2Clk   (PS2Clk),
  .PS2Data  (PS2Data),

  .led      (led),
  .Vsync    (Vsync),
  .Hsync    (Hsync),
  .vgaRed   (vgaRed),
  .vgaGreen (vgaGreen),
  .vgaBlue  (vgaBlue),
  .seg      (seg),
  .an       (an),
  .dp       (dp)
);


// ----- Frame capture -----
// tiff_writer writes one pixel on every falling edge of its clock while a
// file is open. Its clock only pulses for visible pixels, so each image is
// exactly HOR_PIXELS x VER_PIXELS with no blanking area.
initial begin
  go        = '0;
  cap_clk   = 1'b0;
  capturing = 1'b0;
  cap_rgb   = '0;
end

always @(posedge pix_clk) begin
  #1;
  if (capturing && !dut.u_top_vga.output_vga.hblnk && !dut.u_top_vga.output_vga.vblnk) begin
    cap_rgb = dut.u_top_vga.output_vga.rgb;

    cap_pixels++;
    if (cap_rgb != 12'h000)                         cap_lit_pixels++;
    if (cap_pixels > 1 && cap_rgb != cap_prev_rgb)  cap_colour_changes++;
    cap_prev_rgb = cap_rgb;

    cap_clk = 1'b1;
    #1 cap_clk = 1'b0;
  end
end

tiff_writer #(
  .XDIM      (HOR_PIXELS),
  .YDIM      (VER_PIXELS),
  .FILE_DIR  (SHOT_DIR),
  .FILE_NAME ("menu")
) u_tiff_menu (
  .clk (cap_clk),
  .r   ({cap_rgb[11:8], cap_rgb[11:8]}),
  .g   ({cap_rgb[7:4],  cap_rgb[7:4]}),
  .b   ({cap_rgb[3:0],  cap_rgb[3:0]}),
  .go  (go[SHOT_MENU])
);

tiff_writer #(
  .XDIM      (HOR_PIXELS),
  .YDIM      (VER_PIXELS),
  .FILE_DIR  (SHOT_DIR),
  .FILE_NAME ("gameplay")
) u_tiff_gameplay (
  .clk (cap_clk),
  .r   ({cap_rgb[11:8], cap_rgb[11:8]}),
  .g   ({cap_rgb[7:4],  cap_rgb[7:4]}),
  .b   ({cap_rgb[3:0],  cap_rgb[3:0]}),
  .go  (go[SHOT_GAMEPLAY])
);

tiff_writer #(
  .XDIM      (HOR_PIXELS),
  .YDIM      (VER_PIXELS),
  .FILE_DIR  (SHOT_DIR),
  .FILE_NAME ("game_over")
) u_tiff_game_over (
  .clk (cap_clk),
  .r   ({cap_rgb[11:8], cap_rgb[11:8]}),
  .g   ({cap_rgb[7:4],  cap_rgb[7:4]}),
  .b   ({cap_rgb[3:0],  cap_rgb[3:0]}),
  .go  (go[SHOT_GAME_OVER])
);


`TEST_SUITE_BEGIN

    `TEST_SUITE_SETUP begin
      force dut.left       = 1'b0;
      force dut.right      = 1'b0;
      mouse_x = 12'd0;
      mouse_y = 12'd0;
      force dut.mouse_xpos = mouse_x;
      force dut.mouse_ypos = mouse_y;
    end

    `TEST_CASE_SETUP begin
      Reset();
      `CHECK_EQUAL(dut.main_state, BANNER);
    end

    `TEST_CASE("MENU") begin
      GoToMenu();
      // Hover over a level button so the cursor shows up in the picture
      SetMouse(MENU_MEDIUM_X, MENU_MEDIUM_Y);
      WaitFrames(1);
      CaptureFrame(SHOT_MENU);
    end

    `TEST_CASE("GAMEPLAY") begin
      int row, col;

      StartGame();

      `CHECK_EQUAL(FindSafeField(row, col), 1, "No safe field on the board");
      ClickField(row, col, 1'b0);
      `CHECK_EQUAL(dut.main_state, PLAY);

      FlagMinesNextToRevealed();
      `CHECK_EQUAL(dut.main_state, PLAY);

      // Park the cursor over a field that is still covered
      if (FindCoveredField(row, col))
        SetMouse(FieldX(col) + FIELD_SIZE/4, FieldY(row) + FIELD_SIZE/4);

      WaitFrames(2);
      CaptureFrame(SHOT_GAMEPLAY);
    end

    `TEST_CASE("GAME_OVER") begin
      int row, col;

      StartGame();

      `CHECK_EQUAL(FindSafeField(row, col), 1, "No safe field on the board");
      ClickField(row, col, 1'b0);

      `CHECK_EQUAL(FindMine(row, col), 1, "No mine on the board");
      ClickField(row, col, 1'b0);

      WaitPixClk(10);
      $display("[%0t] Stepped on a mine", $time);
      `CHECK_EQUAL(dut.main_state, GAME_OVER);

      WaitFrames(2);
      CaptureFrame(SHOT_GAME_OVER);
    end

`TEST_SUITE_END

`WATCHDOG(2s)


// ----- Capture -----
task automatic CaptureFrame(input int shot);
  cap_pixels         = 0;
  cap_lit_pixels     = 0;
  cap_colour_changes = 0;

  // Open the file during vertical blanking, before the first visible pixel
  @(posedge pix_clk iff dut.u_top_vga.output_vga.vblnk);
  go[shot]  = 1'b1;
  capturing = 1'b1;

  @(posedge pix_clk iff !dut.u_top_vga.output_vga.vblnk);
  go[shot] = 1'b0;

  // Close it on the first blanking line after the last visible one
  @(posedge pix_clk iff dut.u_top_vga.output_vga.vblnk);
  capturing = 1'b0;
  go[shot]  = 1'b1;
  WaitPixClk(2);
  go[shot]  = 1'b0;

  $display("Captured frame %0d: %0d pixels, %0d lit, %0d colour changes",
           shot, cap_pixels, cap_lit_pixels, cap_colour_changes);

  `CHECK_EQUAL(cap_pixels, HOR_PIXELS * VER_PIXELS, "Incomplete frame");
  `CHECK_GREATER(cap_lit_pixels, (HOR_PIXELS * VER_PIXELS) / 10, "Frame is mostly black");
  `CHECK_GREATER(cap_colour_changes, 1000, "Frame has no content");
endtask


// ----- Game flow -----
task automatic GoToMenu();
  SetMouse(12'd10, 12'd10);
  Click(1'b0);
  WaitPixClk(10);
  `CHECK_EQUAL(dut.main_state, MENU);
endtask

task automatic StartGame();
  GoToMenu();
  SetMouse(MENU_MEDIUM_X, MENU_MEDIUM_Y);
  Click(1'b0);
  WaitPixClk(10);
  `CHECK_EQUAL(dut.main_state, PLAY);

  wait (dut.planting_complete);
  WaitDefuser();
  $display("[%0t] Board ready", $time);
  `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], M_ROW_COLUMN_NUMBER);
endtask

task automatic ClickField(input int row, input int col, input bit right_button);
  $display("[%0t] %s click on field (%0d, %0d)", $time, right_button ? "Right" : "Left", row, col);
  SetMouse(FieldX(col) + FIELD_SIZE/2, FieldY(row) + FIELD_SIZE/2);
  Click(right_button);
  WaitDefuser();
endtask

task automatic FlagMinesNextToRevealed();
  int flags = 0;

  for (int r = 0; r < BoardSize(); r++)
    for (int c = 0; c < BoardSize(); c++)
      if (flags < MAX_FLAGS && dut.u_defuser.game_board_mem[r][c].mine && HasRevealedNeighbour(r, c)) begin
        ClickField(r, c, 1'b1);
        flags++;
      end

  $display("Placed %0d flags", flags);
endtask


// ----- Board inspection -----
// Prefers an empty field (no neighbouring mines) closest to the board
// centre, so the flood fill opens a large area in the middle.
function automatic bit FindSafeField(output int row, output int col);
  int best_dist = -1;
  int centre    = BoardSize() - 1;   // doubled, avoids fractions
  bit found_empty = 0;

  for (int r = 0; r < BoardSize(); r++)
    for (int c = 0; c < BoardSize(); c++) begin
      int  distance  = (2*r - centre)**2 + (2*c - centre)**2;
      bit  empty = dut.u_defuser.game_board_mem[r][c].mine_ind == 0;

      if (dut.u_defuser.game_board_mem[r][c].mine)
        continue;

      if ((empty && !found_empty) || (empty == found_empty && (best_dist < 0 || distance < best_dist))) begin
        row = r;
        col = c;
        best_dist   = distance;
        found_empty = empty;
      end
    end

  return best_dist >= 0;
endfunction

function automatic bit FindMine(output int row, output int col);
  for (int r = 0; r < BoardSize(); r++)
    for (int c = 0; c < BoardSize(); c++)
      if (dut.u_defuser.game_board_mem[r][c].mine && !dut.u_defuser.game_board_mem[r][c].flag) begin
        row = r;
        col = c;
        return 1;
      end
  return 0;
endfunction

function automatic bit FindCoveredField(output int row, output int col);
  for (int r = BoardSize() - 1; r >= 0; r--)
    for (int c = BoardSize() - 1; c >= 0; c--)
      if (!dut.u_defuser.game_board_mem[r][c].defused && !dut.u_defuser.game_board_mem[r][c].flag) begin
        row = r;
        col = c;
        return 1;
      end
  return 0;
endfunction

function automatic bit HasRevealedNeighbour(input int row, input int col);
  for (int dr = -1; dr <= 1; dr++)
    for (int dc = -1; dc <= 1; dc++) begin
      int r = row + dr;
      int c = col + dc;
      if (r >= 0 && r < BoardSize() && c >= 0 && c < BoardSize() &&
          dut.u_defuser.game_board_mem[r][c].defused)
        return 1;
    end
  return 0;
endfunction

function automatic int BoardSize();
  return dut.u_defuser.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM];
endfunction

function automatic logic [11:0] FieldX(input int col);
  return dut.u_defuser.game_setup_cashe[BOARD_XPOS_REG_NUM] + col * FIELD_SIZE;
endfunction

function automatic logic [11:0] FieldY(input int row);
  return dut.u_defuser.game_setup_cashe[BOARD_YPOS_REG_NUM] + row * FIELD_SIZE;
endfunction


// ----- Low level helpers -----
// Waits until the defuser has finished processing the last click
task automatic WaitDefuser();
  WaitPixClk(10);
  while (dut.u_defuser.defuser_state.name() != "DEF_WAIT_FOR_MOUSE" &&
         dut.u_defuser.defuser_state.name() != "DEF_GAME_OVER")
    WaitPixClk(1);
endtask

task automatic Reset();
  rst = 1'b1;
  wait (locked);
  WaitPixClk(20);
  rst = 1'b0;
  WaitPixClk(20);
endtask

task automatic SetMouse(input logic [11:0] xpos, input logic [11:0] ypos);
  mouse_x = xpos;
  mouse_y = ypos;
endtask

task automatic Click(input bit right_button);
  @(posedge pix_clk);
  if (right_button) force dut.right = 1'b1;
  else              force dut.left  = 1'b1;
  WaitPixClk(4);
  force dut.left  = 1'b0;
  force dut.right = 1'b0;
  WaitPixClk(4);
endtask

task automatic WaitFrames(input int num_of_frames);
  repeat (num_of_frames) @(posedge dut.u_top_vga.output_vga.vblnk);
endtask

task automatic WaitPixClk(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge pix_clk);
endtask

endmodule

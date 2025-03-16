# Copyright (C) 2023  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project details required for generate_bitstream.tcl
# These files are auto-filled by generate_bitstream script.
# If you want to edit search paths or project parameters
# edit add_files_to_tcl file.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name
set project_name Saper_new

# Top module name
set top_module top_vga_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location
set xdc_files {
    constraints/clk_wiz_0.xdc
    constraints/top_vga_basys3.xdc
}

# Specify SystemVerilog design files location
set sv_files {
    ../rtl/common/cross_buffer.sv
    ../rtl/common/delay_vga.sv
    ../rtl/common/edge_detector.sv
    ../rtl/memory/wishbone_arbiter.sv
    ../rtl/memory/wishbone_board_mem.sv
    ../rtl/memory/wishbone_if.sv
    ../rtl/memory/wishbone_master.sv
    ../rtl/mouse/draw_mouse.sv
    ../rtl/mouse/top_mouse.sv
    ../rtl/timer/bin2bcd.sv
    ../rtl/timer/time_controller.sv
    ../rtl/timer/top_timer.sv
    ../rtl/top_vga/draw_back_objects.sv
    ../rtl/top_vga/draw_bg.sv
    ../rtl/top_vga/draw_board.sv
    ../rtl/top_vga/draw_image.sv
    ../rtl/top_vga/draw_rect.sv
    ../rtl/top_vga/image_rom.sv
    ../rtl/top_vga/top_draw_board.sv
    ../rtl/top_vga/top_vga.sv
    ../rtl/top_vga/vga_if.sv
    ../rtl/top_vga/vga_out.sv
    ../rtl/top_vga/vga_pkg.sv
    ../rtl/top_vga/vga_timing.sv
    ../rtl/z_game_setup/game_pkg.sv
    ../rtl/z_game_setup/main_fsm.sv
    rtl/top_vga_basys3.sv
}

# Specify Verilog design files location
set verilog_files {
    ../rtl/common/delay.v
    ../rtl/sseg_disp.v
    rtl/clk_wiz_0.v
    rtl/clk_wiz_0_clk_wiz.v
}

# Specify VHDL design files location
set vhdl_files {
    ../rtl/mouse/MouseCtl.vhd
    ../rtl/mouse/MouseDisplay.vhd
    ../rtl/mouse/Ps2Interface.vhd
}

# Specify files for a memory initialization
set mem_files {
    ../rtl/top_vga/data/agh.data
    ../rtl/top_vga/data/bomb.data
    ../rtl/top_vga/data/flag.data
}


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
    ../rtl/edge_detector.sv
    ../rtl/memory.sv
    ../rtl/mouse/draw_mouse.sv
    ../rtl/mouse/top_mouse.sv
    ../rtl/timer/bin2bcd.sv
    ../rtl/timer/time_controller.sv
    ../rtl/timer/top_timer.sv
    ../rtl/top_draw_board/draw_bg.sv
    ../rtl/top_draw_board/top_draw_board.sv
    ../rtl/top_draw_board/vga_timing.sv
    ../rtl/top_vga.sv
    ../rtl/vga_if.sv
    ../rtl/vga_output_module.sv
    ../rtl/vga_pkg.sv
    ../rtl/whishbone_if.sv
    rtl/top_vga_basys3.sv
}

# Specify Verilog design files location
set verilog_files {
    ../rtl/list_ch04_15_disp_hex_mux.v
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
# set mem_files {
#     path/to/file.data
# }


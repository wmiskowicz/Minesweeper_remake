import os
import sys

from XVunit.internals.python.xvunit import XVunit
from XVunit.path_settings import PROJECT_DIR

xvunit = XVunit()

sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "memory", "wishbone_if.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "memory", "wishbone_master.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga_pkg.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "lfsr.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "game_pkg.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "mine_planter.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "mine_planter.svh")
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "mine_planter", "*.sv"),
        os.path.join(PROJECT_DIR, "XVunit", "internals", "verilog", "*.sv")
    ],
}

xvunit.set_parameters(
    sources=sources
)

xvunit.run(argv=sys.argv)

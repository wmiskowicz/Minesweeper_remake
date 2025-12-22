import os
import sys

from XVunit.internals.python.run_XVUnitCommon import run_XVUnitCommon
from XVunit.internals.python.paths import PROJECT_DIR


XVUnitCommon = run_XVUnitCommon()



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
        os.path.join(PROJECT_DIR, "XVUnit", "internals", "verilog", "*.sv")
    ],
}



XVUnitCommon.set_parameters(
    sources=sources
)


XVUnitCommon.run(argv=sys.argv)
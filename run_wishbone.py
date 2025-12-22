from XVunit.internals.python.run_XVUnitCommon import run_XVUnitCommon
from XVunit.internals.python.paths import PROJECT_DIR
import os
import sys

XVUnitCommon = run_XVUnitCommon()



sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "memory", "*.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "game_pkg.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga_pkg.sv"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "wishbone_arbiter", "*.sv"),
        os.path.join(PROJECT_DIR, "XVUnit", "internals", "verilog", "xvunit_pkg.sv"),
    ],
}



XVUnitCommon.set_parameters(
    sources=sources
)


XVUnitCommon.run(argv=sys.argv)
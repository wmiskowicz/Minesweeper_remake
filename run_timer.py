from XVunit.internals.python.xvunit import XVunit
from XVunit.path_settings import PROJECT_DIR
import os
import sys

xvunit = XVunit()



sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "timer", "*.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "game_pkg.sv")
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "timer", "*.sv"),
        os.path.join(PROJECT_DIR, "XVunit", "internals", "verilog", "*.sv"),
    ],
}



xvunit.set_parameters(
    sources=sources
)


xvunit.run(argv=sys.argv)
import os
import sys

HERE        = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))

os.environ.setdefault("XVUNIT_BUILD_DIR", os.path.join(HERE, "xvunit_out"))
sys.path.insert(0, PROJECT_DIR)

from XVunit.internals.python.xvunit import XVunit
from XVunit.path_settings import PROJECT_DIR

xvunit = XVunit()


sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "memory", "*.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "z_game_setup", "game_pkg.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga_pkg.sv"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "wishbone_arbiter", "*.sv"),
        os.path.join(PROJECT_DIR, "XVunit", "internals", "verilog", "xvunit_pkg.sv"),
    ],
}



xvunit.set_parameters(
    sources=sources
)


xvunit.run(argv=sys.argv)
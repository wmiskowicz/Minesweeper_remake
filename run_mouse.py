import os
import sys

from XVunit.internals.python.run_XVUnitCommon import run_XVUnitCommon
from XVunit.internals.python.paths import PROJECT_DIR


XVUnitCommon = run_XVUnitCommon()



sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga_pkg.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "common", "posedge_detector.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "mouse", "*.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "mouse", "*.vhd"),
        os.path.join(PROJECT_DIR, 'rtl', "mouse", "fifo", "*.vhd"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "top_mouse", "*.sv"),
        os.path.join(PROJECT_DIR, "XVUnit", "internals", "verilog", "*.sv")
    ],
}



XVUnitCommon.set_parameters(
    sources=sources
)


XVUnitCommon.run(argv=sys.argv)
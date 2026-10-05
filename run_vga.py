import os
import sys

from XVunit.internals.python.xvunit import XVunit
from XVunit.path_settings import PROJECT_DIR


xvunit = XVunit()



sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga*.sv"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "vga_timing", "*.sv"),
        os.path.join(PROJECT_DIR, "sim", "vga_out", "*.sv"),
        os.path.join(PROJECT_DIR, "XVunit", "internals", "verilog", "*.sv")
    ],
}



xvunit.set_parameters(
    sources=sources
)


xvunit.run(argv=sys.argv)
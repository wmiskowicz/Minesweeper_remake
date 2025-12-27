import os
import sys

from XVunit.internals.python.run_XVUnitCommon import run_XVUnitCommon
from XVunit.internals.python.paths import PROJECT_DIR


XVUnitCommon = run_XVUnitCommon()



sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "top_vga", "vga*.sv"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "vga_timing", "*.sv"),
        os.path.join(PROJECT_DIR, "sim", "vga_out", "*.sv"),
        os.path.join(PROJECT_DIR, "XVUnit", "internals", "verilog", "*.sv")
    ],
}



XVUnitCommon.set_parameters(
    sources=sources
)


XVUnitCommon.run(argv=sys.argv)
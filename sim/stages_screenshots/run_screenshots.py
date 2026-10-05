import glob
import os
import sys

HERE        = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))

os.environ.setdefault("XVUNIT_BUILD_DIR", os.path.join(HERE, "xvunit_out"))
sys.path.insert(0, PROJECT_DIR)

from XVunit.internals.python.xvunit import XVunit
from XVunit.path_settings import PROJECT_DIR


SHOT_DIR  = os.path.join(PROJECT_DIR, "results", "screenshots")
MEDIA_DIR = os.path.join(PROJECT_DIR, "doc", "media")

xvunit = XVunit()

sources = {
    "rtl": [
        os.path.join(PROJECT_DIR, 'rtl', "**", "*.sv"),
        os.path.join(PROJECT_DIR, 'rtl', "**", "*.v"),
        os.path.join(PROJECT_DIR, 'rtl', "**", "*.vhd"),
        os.path.join(PROJECT_DIR, 'fpga', "rtl", "**", "*.sv"),
        os.path.join(PROJECT_DIR, 'fpga', "rtl", "**", "*.v"),
    ],
    "sim": [
        os.path.join(PROJECT_DIR, "sim", "common", "*"),
        os.path.join(PROJECT_DIR, "sim", "stages_screenshots", "*.sv"),
        os.path.join(PROJECT_DIR, "XVunit", "internals", "verilog", "*.sv")
    ],
}

xvunit.set_parameters(
    sources=sources
)


def convert_to_png():
    """Converts captured .tif frames to .png so the README can show them."""
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not installed, skipping PNG conversion (pip install pillow)")
        return

    os.makedirs(MEDIA_DIR, exist_ok=True)
    for tif_path in glob.glob(os.path.join(SHOT_DIR, "*.tif")):
        png_path = os.path.join(MEDIA_DIR, os.path.basename(tif_path).replace(".tif", ".png"))
        Image.open(tif_path).save(png_path)
        print(f"Saved {png_path}")


os.makedirs(SHOT_DIR, exist_ok=True)
try:
    xvunit.run(argv=sys.argv)
except SystemExit:
    pass
convert_to_png()

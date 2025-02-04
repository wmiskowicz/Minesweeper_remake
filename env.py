# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# Initialize environment for working with the project.

import os
import subprocess
import shutil
import sys

# Change these constants according to your system
VIVADO_DIR = r"C:\Xilinx\Vivado\2023.1\bin"
VIVADO_SETUP = r"C:\Xilinx\Vivado\2023.1\settings64.bat"
# ================================================

ROOT_DIR = os.getcwd()
os.environ["ROOT_DIR"] = ROOT_DIR
os.environ["VIVADO_DIR"] = VIVADO_DIR
os.environ["VIVADO_SETUP"] = VIVADO_SETUP
os.environ["PATH"] = os.path.join(ROOT_DIR, "tools") + os.pathsep + os.environ["PATH"]

if not os.path.exists(".git"):
    subprocess.run(["git", "init"])
    subprocess.run(["git", "add", "."], check=True)

try:
    import colorama
except ImportError:
    print("Colorama not found. Installing...")
    subprocess.run([sys.executable, "-m", "pip", "install", "colorama"], check=True)
    print("Colorama installed successfully.")

# Copy glbl.v file if missing
glbl_src = os.path.join(VIVADO_DIR, "..", "data", "verilog", "src", "glbl.v")
glbl_dest = os.path.join("sim", "common", "glbl.v")

if not os.path.exists(glbl_dest):
    os.makedirs(os.path.dirname(glbl_dest), exist_ok=True)
    shutil.copy(glbl_src, glbl_dest)

with open(".env", "w") as f:
    f.write(f'ROOT_DIR="{ROOT_DIR}"\n')
    f.write(f'VIVADO_DIR="{VIVADO_DIR}"\n')
    f.write(f'VIVADO_SETUP="{VIVADO_SETUP}"\n')

print("Environment setup complete.")

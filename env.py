# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# Initialize environment for working with the project.
import os
import subprocess
import shutil


ROOT_DIR = os.getcwd()
os.environ["ROOT_DIR"] = ROOT_DIR
os.environ["PATH"] = os.path.join(ROOT_DIR, "tools") + os.pathsep + os.environ["PATH"]

VIVADO_DIR = os.getenv("VIVADO_DIR")

if not VIVADO_DIR:
    print("Error: VIVADO_DIR environment variable is not set. Please set it before running this script.")
    exit(1)

os.environ["VIVADO_DIR"] = VIVADO_DIR

# Initialize a Git repository if not already present
if not os.path.exists(".git"):
    subprocess.run(["git", "init"])
    subprocess.run(["git", "add", "."], check=True)

# Copy glbl.v from Vivado installation directory for IP simulation
glbl_src = os.path.join(VIVADO_DIR, "data", "verilog", "src", "glbl.v")
glbl_dest = os.path.join("sim", "common", "glbl.v")

if not os.path.exists(glbl_dest):
    os.makedirs(os.path.dirname(glbl_dest), exist_ok=True)
    shutil.copy(glbl_src, glbl_dest)

with open(".env", "w") as f:
    f.write(f'ROOT_DIR="{ROOT_DIR}"\n')
    f.write(f'VIVADO_DIR="{VIVADO_DIR}"\n')

print("Environment setup complete.")

# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# This script runs Vivado in tcl mode and sources an appropriate tcl file to run
# all the steps to generate bitstream. When finished, the bitstream is copied to
# the result directory. Additionally, all warnings and errors logged during
# synthesis and implementation are also copied to results/warning_summary.log.
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

import os
import glob
import subprocess
import shutil
import sys

# Load ROOT_DIR and VIVADO_DIR from .env file
ENV_FILE = ".env"
ROOT_DIR = None
VIVADO_DIR = None

if os.path.exists(ENV_FILE):
    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith("ROOT_DIR="):
                ROOT_DIR = line.strip().split("=")[1].strip('"')
            elif line.startswith("VIVADO_DIR="):
                VIVADO_DIR = line.strip().split("=")[1].strip('"')

if not ROOT_DIR:
    print("Error: ROOT_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

if not VIVADO_DIR:
    print("Error: VIVADO_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

# Locate the correct Vivado executable
vivado_executable = os.path.join(VIVADO_DIR, "vivado.bat")

if not os.path.exists(vivado_executable):
    print(f"Error: Vivado executable not found at {vivado_executable}. Check VIVADO_DIR path.")
    sys.exit(1)

# Clean untracked files in the fpga directory
subprocess.run(["git", "clean", "-fXd", "fpga"], cwd=ROOT_DIR)

# Run Vivado in TCL mode to generate the bitstream
fpga_dir = os.path.join(ROOT_DIR, "fpga")
tcl_script = os.path.join(fpga_dir, "scripts", "generate_bitstream.tcl")

command = f'"{vivado_executable}" -mode tcl -source "{tcl_script}"'
subprocess.run(command, shell=True, cwd=fpga_dir)

# Copy generated bitstream to results directory
bitstream_files = glob.glob(os.path.join(fpga_dir, "build", "*.bit"))

if not bitstream_files:
    print("Error: No bitstream (.bit) file found in fpga/build.")
    sys.exit(1)

results_dir = os.path.join(ROOT_DIR, "results")
os.makedirs(results_dir, exist_ok=True)

for bitstream_file in bitstream_files:
    shutil.copy(bitstream_file, results_dir)

print(f"Copied bitstream to {results_dir}")

# Run warning summary script
warning_summary_script = os.path.join(ROOT_DIR, "tools", "warning_summary.py")

if os.path.exists(warning_summary_script):
    subprocess.run(["python", warning_summary_script], cwd=ROOT_DIR)
else:
    print("Warning: warning_summary.py not found in tools/ directory.")

print("Bitstream generation and logging completed successfully.")

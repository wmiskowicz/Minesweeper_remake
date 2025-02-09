# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# Load a bitstream to a Xilinx FPGA using Vivado in tcl mode.

import os
import glob
import subprocess
import sys
import colorama

ENV_FILE = ".env"
ROOT_DIR = None
VIVADO_DIR = None

colorama.init(autoreset=True)

if os.path.exists(ENV_FILE):
    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith("ROOT_DIR="):
                ROOT_DIR = line.strip().split("=")[1].strip('"')
            elif line.startswith("VIVADO_DIR="):
                VIVADO_DIR = line.strip().split("=")[1].strip('"')

if not ROOT_DIR:
    print(colorama.Fore.YELLOW + "ROOT_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

if not VIVADO_DIR:
    print(colorama.Fore.YELLOW + "VIVADO_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

vivado_bin = os.path.join(VIVADO_DIR, "bin")
os.environ["PATH"] = vivado_bin + os.pathsep + os.environ["PATH"]


bitstream_files = glob.glob(os.path.join(ROOT_DIR, "results", "*.bit"))

if not bitstream_files:
    print(colorama.Fore.RED + "Error: No .bit file found in the results directory.")
    sys.exit(1)

bitstream_file = bitstream_files[0] 
tcl_script = os.path.join(ROOT_DIR, "fpga", "scripts", "program_fpga.tcl")


command = f'{VIVADO_DIR}/vivado.bat -mode tcl -source "{tcl_script}" -tclargs "{bitstream_file}"'
subprocess.run(command, shell=True)

print(colorama.Fore.GREEN + f"Bitstream {bitstream_file} programmed successfully.")

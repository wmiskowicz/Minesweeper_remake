# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

import os
import glob
import subprocess
import shutil
import sys
import colorama
from add_files_to_tcl import update_generate_bitstream_tcl

ENV_FILE   = ".env"
ROOT_DIR   = None
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

vivado_executable = os.path.join(VIVADO_DIR, "vivado.bat")

if not os.path.exists(vivado_executable):
    print(colorama.Fore.RED + f"Error: Vivado executable not found at {vivado_executable}.")
    sys.exit(1)

def list_bit_files(search_path="."):
    """
    Recursively searches for all .bit files in the given directory and subdirectories.
    Prints the found files with absolute paths.
    """
    bit_files = []

    for root, _, files in os.walk(search_path):
        for file in files:
            if file.endswith(".bit"):
                bit_files.append(os.path.abspath(os.path.join(root, file)))

    return bit_files
# ------------------------------------------------------------------------------
# MAIN script flow
#  1) Update project_details.tcl with fresh file lists
#  2) Clean untracked files
#  3) Run Vivado
#  4) Copy bitstream + run warning summary
# ------------------------------------------------------------------------------
def main():
    # (1) Update the .tcl file with fresh list of sources
    update_generate_bitstream_tcl()

    # (2) Clean untracked files in the fpga directory
    subprocess.run(["git", "clean", "-fXd", "fpga"], cwd=ROOT_DIR)

    # (3) Run Vivado in TCL mode to generate the bitstream
    fpga_dir   = os.path.join(ROOT_DIR, "fpga")
    main_tcl   = os.path.join(fpga_dir, "scripts", "generate_bitstream.tcl")
    command    = f'"{vivado_executable}" -mode tcl -source "{main_tcl}"'
    subprocess.run(command, shell=True, cwd=fpga_dir)

    # (4) Copy generated bitstream to results directory
    bitstream_files = list_bit_files(os.path.join(fpga_dir, "build"))
    if not bitstream_files:
        print(colorama.Fore.RED + "Error: No bitstream (.bit) file found in fpga/build.")
        sys.exit(1)

    results_dir = os.path.join(ROOT_DIR, "results")
    os.makedirs(results_dir, exist_ok=True)

    for bitstream_file in bitstream_files:
        shutil.copy(bitstream_file, results_dir)
    print(f"Copied bitstream(s) to {results_dir}")

    # Run warning summary script
    warning_summary_script = os.path.join(ROOT_DIR, "tools", "warning_summary.py")
    if os.path.exists(warning_summary_script):
        subprocess.run(["python", warning_summary_script], cwd=ROOT_DIR)
    else:
        print("Warning: warning_summary.py not found in tools/ directory.")

    print(colorama.Fore.GREEN + "Bitstream generation and logging completed successfully.")

if __name__ == "__main__":
    main()

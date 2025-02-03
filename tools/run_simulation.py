# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# This script runs simulations outside Vivado, making them faster.
# For usage details, run the script with no arguments.
# For more information see: AMD Xilinx UG 900:
# https://docs.xilinx.com/r/en-US/ug900-vivado-logic-simulation/Simulating-in-Batch-or-Scripted-Mode-in-Vivado-Simulator
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

import os
import sys
import subprocess
import glob
import argparse

# Load ROOT_DIR from .env file
ENV_FILE = ".env"
ROOT_DIR = None

if os.path.exists(ENV_FILE):
    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith("ROOT_DIR="):
                ROOT_DIR = line.strip().split("=")[1].strip('"')
                break

if not ROOT_DIR:
    print("Error: ROOT_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

SIM_DIR = os.path.join(ROOT_DIR, "sim")
BUILD_DIR = os.path.join(SIM_DIR, "build")

# Ensure build directory exists
os.makedirs(BUILD_DIR, exist_ok=True)

def list_available_tests():
    """List all available tests in the sim directory, excluding non-test folders."""
    tests = [name for name in os.listdir(SIM_DIR) if os.path.isdir(os.path.join(SIM_DIR, name))
             and name not in ["build", "common"]]
    if tests:
        print("\n".join(tests))
    else:
        print("No tests found.")
    sys.exit(0)

def execute_test(test_name, show_gui):
    """Run the specified test with or without GUI."""
    # Clean untracked files
    subprocess.run(["git", "clean", "-fXd", "."], cwd=SIM_DIR)

    test_path = os.path.join(SIM_DIR, test_name)
    project_file = os.path.join(test_path, f"{test_name}.prj")

    # Check if glbl.v is included
    compile_glbl = "work.glbl" if "glbl.v" in open(project_file).read() else ""

    xelab_opts = f"work.{test_name}_tb {compile_glbl} -snapshot {test_name}_tb -prj {project_file} -timescale 1ns/1ps -L unisims_ver"

    # Run simulation
    if show_gui:
        subprocess.run(f"xelab {xelab_opts} -debug typical", shell=True, cwd=BUILD_DIR)
        subprocess.run(f"xsim {test_name}_tb -gui -t {os.path.join(ROOT_DIR, 'tools', 'sim_cmd.tcl')}", shell=True, cwd=BUILD_DIR)
    else:
        process = subprocess.run(f"xelab {xelab_opts} -standalone -runall", shell=True, cwd=BUILD_DIR, stdout=subprocess.PIPE, text=True)
        for line in process.stdout.splitlines():
            if any(keyword in line.lower() for keyword in ["fatal", "error", "critical", "warning"]):
                print(line)

def run_all():
    """Run all available tests and summarize results."""
    tests = [name for name in os.listdir(SIM_DIR) if os.path.isdir(os.path.join(SIM_DIR, name))
             and name not in ["build", "common"]]
    
    if not tests:
        print("No tests found.")
        sys.exit(1)

    for test in tests:
        print(f"Running {test}: ", end="")
        process = subprocess.run(["python", __file__, "-t", test], stdout=subprocess.PIPE, text=True)
        error_count = process.stdout.lower().count("error")
        
        if error_count == 0:
            print("\033[1;32mPASSED\033[0;39m")  # Green PASSED
        else:
            print("\033[1;31mFAILED\033[0;39m")  # Red FAILED
    sys.exit(0)

# Argument parsing
parser = argparse.ArgumentParser(description="Run Vivado simulations outside Vivado for faster execution.")
parser.add_argument("-l", action="store_true", help="List available tests")
parser.add_argument("-t", type=str, help="Run the specified test")
parser.add_argument("-g", action="store_true", help="Show GUI (use with -t)")
parser.add_argument("-a", action="store_true", help="Run all available tests")

args = parser.parse_args()

if args.l:
    list_available_tests()
elif args.a:
    run_all()
elif args.t:
    execute_test(args.t, args.g)
else:
    parser.print_help()
    sys.exit(1)

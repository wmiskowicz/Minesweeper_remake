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
import colorama
import time

ENV_FILE = ".env"
ROOT_DIR = None
VIVADO_SETUP = None

MAX_SIM_TIME = 60 # seconds 

colorama.init(autoreset=True)

if os.path.exists(ENV_FILE):
    with open(ENV_FILE, "r") as f:
        for line in f:
            key, value = line.strip().split("=")
            value = value.strip('"')
            if key == "ROOT_DIR":
                ROOT_DIR = value
            elif key == "VIVADO_SETUP":
                VIVADO_SETUP = value

if not ROOT_DIR:
    print(colorama.Fore.YELLOW + "ROOT_DIR is not set. Run env.py first to initialize it.")
    sys.exit(1)

if not VIVADO_SETUP:
    print(colorama.Fore.YELLOW + "VIVADO_SETUP is not set in .env. Run env.py first to initialize it.")
    sys.exit(1)

SIM_DIR = os.path.join(ROOT_DIR, "sim")
BUILD_DIR = os.path.join(SIM_DIR, "build")

SETUP_CMD = f'call "{VIVADO_SETUP}" && '

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
    subprocess.run(["git", "clean", "-fXd", "."], cwd=SIM_DIR)

    if not os.path.exists(BUILD_DIR):
        os.makedirs(BUILD_DIR, exist_ok=True)

    test_path = os.path.join(SIM_DIR, test_name)
    project_file = os.path.join(test_path, f"{test_name}.prj")

    compile_glbl = "work.glbl" if "glbl.v" in open(project_file).read() else ""

    xelab_opts = f"work.{test_name}_tb {compile_glbl} -snapshot {test_name}_tb -prj {project_file} -timescale 1ns/1ps -L unisims_ver"

    if show_gui:
        subprocess.run(f'cmd.exe /c "{SETUP_CMD} xelab {xelab_opts} -debug typical"', cwd=BUILD_DIR)
        subprocess.run(f'cmd.exe /c "{SETUP_CMD} xsim {test_name}_tb -gui -t {os.path.join(ROOT_DIR, "tools", "sim_cmd.tcl").replace("\\", "/")}"', cwd=BUILD_DIR)
    else:
        process = subprocess.run(f'cmd.exe /c "{SETUP_CMD} xelab {xelab_opts} -standalone -runall"',
                                 cwd=BUILD_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        if process.returncode != 0:
            print(colorama.Fore.RED + f"[{test_name}] FAILED (xelab error)" + colorama.Style.RESET_ALL)
            for line in process.stdout.splitlines():
                if line.strip().startswith("ERROR"):
                    print(colorama.Fore.RED + line.strip() + colorama.Style.RESET_ALL)
                else:
                    print(line.strip())
            return
        else:
            for line in process.stdout.splitlines():
                if line.strip().startswith("WARNING"):
                    print(colorama.Fore.YELLOW + line.strip() + colorama.Style.RESET_ALL)
                else:
                    print(line.strip())

        log_file = os.path.join(BUILD_DIR, "xsim.log")

        start_time = time.time()
        while not os.path.exists(log_file):
            if time.time() - start_time > MAX_SIM_TIME:
                print(colorama.Fore.RED + f"[{test_name}] FAILED (xsim.log not found after {MAX_SIM_TIME} seconds)")
                return
            time.sleep(1)

        with open(log_file, "r") as f:
            log_output = f.read().lower()

        failed_keywords = ["fatal", "error", "critical", "failed"]

        is_failed = any(keyword in log_output for keyword in failed_keywords)

        if not is_failed:
            print(colorama.Fore.GREEN + f"[{test_name}] PASSED ")
        else:
            print(colorama.Fore.RED + f"[{test_name}] FAILED ")
            with open(log_file, "r") as f:
                for line in f:
                    if any(keyword in line.lower() for keyword in ["fatal", "error"]):
                        print(colorama.Fore.RED + ">> " + line.strip())
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
            print(colorama.Fore.GREEN + "PASSED")
        else:
            print(colorama.Fore.GREEN + "FAILED")
    sys.exit(0)

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

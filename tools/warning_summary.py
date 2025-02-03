# Author: Wojciech Miskowicz
#
# Description:
# Based on work of Piotr Kaczmarczyk, PhD, AGH University of Krakow.
# Extracts warnings and errors from synthesis and implementation logs.
import os
import re
import glob
from datetime import datetime


PROJECT_PATH = os.path.join("fpga", "build")
LOG_FILE = os.path.join("results", "warning_summary.log")

SYNTH_IGNORE = re.compile(r"\[Constraints\s18-5210\]|\[Netlist\s29-345\]")
IMPL_IGNORE = re.compile(r"replace_with_codes_to_be_ignored_only_when_justified")

os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

with open(LOG_FILE, "w") as log:
    log.write("Warnings, critical warnings, and errors from synthesis and implementation\n")
    log.write(f"Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

    # ---- SYNTHESIS ----
    log.write("----SYNTHESIS----\n")
    synth_logs = glob.glob(os.path.join(PROJECT_PATH, "*.runs", "synth_1", "runme.log"))

    if synth_logs:
        found_warnings = False
        with open(synth_logs[0], "r") as synth_log:
            for line in synth_log:
                if re.search(r"CRITICAL|WARNING|ERROR", line) and not SYNTH_IGNORE.search(line):
                    log.write(line)
                    found_warnings = True
        if not found_warnings:
            log.write("CLEAR :)\n")
    else:
        log.write("No synthesis log file found!\n")

    log.write("\n----IMPLEMENTATION----\n")
    
    # ---- IMPLEMENTATION ----
    impl_logs = glob.glob(os.path.join(PROJECT_PATH, "*.runs", "impl_1", "runme.log"))

    if impl_logs:
        found_warnings = False
        with open(impl_logs[0], "r") as impl_log:
            for line in impl_log:
                if re.search(r"CRITICAL|WARNING|ERROR", line) and not IMPL_IGNORE.search(line):
                    log.write(line)
                    found_warnings = True
        if not found_warnings:
            log.write("CLEAR :)\n")
    else:
        log.write("No implementation log file found!\n")


with open(LOG_FILE, "r") as file:
    log_content = file.read()

log_content = re.sub(r"[A-Za-z]:\\.*?\\fpga\\build\\", "", log_content)

with open(LOG_FILE, "w") as file:
    file.write(log_content)

print(f"Log summary saved to {LOG_FILE}")

# ------------------------------------------------------------------------------
# Author: Wojciech Miskowicz
#
# Description:
# This script is responsible for auto filling simulation .prj file containing
# all project files. It's used by run_simulation script when executed with -prj flag.
# ------------------------------------------------------------------------------
import os

def generate_prj_file(test_name, sim_dir):
    prj_dir = os.path.join(sim_dir, test_name)
    os.makedirs(prj_dir, exist_ok=True)

    prj_path = os.path.join(prj_dir, f"{test_name}.prj")

    script_dir = os.path.dirname(__file__)
    project_dir = os.path.dirname(os.path.dirname(__file__))
    rtl_root = os.path.normpath(os.path.join(script_dir, "../rtl"))  
    common_dir = os.path.normpath(os.path.join(sim_dir, "common"))

    sv_files = []
    v_files = []
    vhdl_files = []

    sim_parent_dir = os.path.dirname(sim_dir)

    def collect_files(root_path, prefix, base_dir):
        """Collect files and set relative paths correctly."""
        for base, _, files in os.walk(root_path):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                rel_path = os.path.relpath(os.path.join(base, f), start=base_dir)
                rel_path = prefix + rel_path.replace("\\", "/") 
                if ext == ".sv":
                    sv_files.append(rel_path)
                elif ext == ".v":
                    v_files.append(rel_path)
                elif ext == ".vhd":
                    vhdl_files.append(rel_path)

    collect_files(rtl_root, "../../", sim_parent_dir) 
    collect_files(common_dir, "../", sim_dir)

    for item in os.listdir(prj_dir):
        full_path = os.path.join(prj_dir, item)
        if os.path.isfile(full_path) and os.path.splitext(item)[1].lower() == ".sv":
            rel_path = os.path.relpath(full_path, start=prj_dir).replace("\\", "/")
            sv_files.append("./" + rel_path) 

    def prioritize_pkg_if(files):
        """Sort so that '_pkg' and '_if' files come first."""
        pkg_if_files = [f for f in files if "_pkg" in f or "_if" in f]
        other_files = [f for f in files if "_pkg" not in f and "_if" not in f]
        return sorted(pkg_if_files) + sorted(other_files)

    sv_files = prioritize_pkg_if(sv_files)
    v_files.sort()
    vhdl_files.sort()

    with open(prj_path, "w") as f:
        f.write("# Copyright (C) 2023  AGH University of Science and Technology\n")
        f.write("# MTM UEC2\n")
        f.write("# Author: Piotr Kaczmarczyk\n")
        f.write("#\n")
        f.write("# Description:\n")
        f.write("# List of files defining the modules used during the test.\n")
        f.write("# This file can be auto-generated using -prj flag of run_simulation script.\n")
        f.write("# Specify the file paths relative to THIS file.\n")
        f.write("# For syntax detail see AMD Xilinx UG 900:\n")
        f.write("# https://docs.xilinx.com/r/en-US/ug900-vivado-logic-simulation/Project-File-.prj-Syntax\n")
        f.write("\n")

        if sv_files:
            f.write("sv work ")
            f.write(" \\\n        ".join(sv_files))
            f.write(" \\\n\n")

        if v_files:
            f.write("verilog work ")
            f.write(" \\\n            ".join(v_files))
            f.write(" \\\n\n")

        if vhdl_files:
            f.write("vhdl work ")
            f.write(" \\\n          ".join(vhdl_files))
            f.write(" \\\n")

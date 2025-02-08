# ------------------------------------------------------------------------------
# Author: Wojciech Miskowicz
#
# Description:
# This script is responsible for auto filling  project_details.tcl file containing
# all project files. It's used by generate_bitstream script. If you want
# change search locations or project parameters edit constants at the begginign of this file.
# ------------------------------------------------------------------------------
import os
import colorama

colorama.init(autoreset=True)

# -------------------------------------------------------------------------
# Project parameters: adjust as needed
# -------------------------------------------------------------------------
PROJECT_NAME = "Saper_new"
TOP_MODULE   = "top_vga_basys3"
TARGET_FPGA  = "xc7a35tcpg236-1"

# -------------------------------------------------------------------------
# Search locations
# -------------------------------------------------------------------------
THIS_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR     = os.path.abspath(os.path.join(THIS_SCRIPT_DIR, ".."))
FPGA_DIR        = os.path.join(PROJECT_DIR, "fpga")

FPGA_CONSTRAINTS_DIR = os.path.join(FPGA_DIR, "constraints")
FPGA_RTL_DIR         = os.path.join(FPGA_DIR, "rtl")
TOP_RTL_DIR          = os.path.join(PROJECT_DIR, "rtl")
MEM_INIT_DIR         = os.path.join(PROJECT_DIR, "rtl")

OUTPUT_TCL = os.path.join(FPGA_DIR, "scripts", "project_details.tcl")

# -------------------------------------------------------------------------
def collect_files_abs(root_dir, extensions):
    """
    Recursively scan 'root_dir' (absolute path) for files with the given 'extensions',
    returning a sorted list of absolute file paths.
    """
    collected = []
    if not os.path.isdir(root_dir):
        return collected 

    for base, dirs, files in os.walk(root_dir):
        for filename in files:
            _, ext = os.path.splitext(filename)
            if ext.lower() in extensions:
                full_path = os.path.join(base, filename)
                collected.append(os.path.abspath(full_path))

    return sorted(collected)

def prioritize_pkg_if(file_list):
    """
    Sort so that files containing '_pkg' or '_if' in their name appear first,
    preserving alphabetical order in each group.
    """
    pkg_if = [f for f in file_list if ("_pkg" in os.path.basename(f).lower() 
                                       or "_if"  in os.path.basename(f).lower())]
    other  = [f for f in file_list if f not in pkg_if]
    return sorted(pkg_if) + sorted(other)

# -------------------------------------------------------------------------
def update_generate_bitstream_tcl():
    """
    Gathers XDC, SV, V, VHDL, and MEM (.data) files from:
      - fpga/constraints
      - fpga/rtl (local)
      - <project>/rtl (parent)
      - fpga/mem (for memory .data files)
    Then writes them into fpga/scripts/project_details.tcl
    using paths relative to fpga/.
    """

    # Collect .xdc, .sv, .v, .vhd
    xdc_abs = collect_files_abs(FPGA_CONSTRAINTS_DIR, {".xdc"})
    sv_abs, v_abs, vhdl_abs = [], [], []

    sv_abs   += collect_files_abs(FPGA_RTL_DIR, {".sv"})
    v_abs    += collect_files_abs(FPGA_RTL_DIR, {".v"})
    vhdl_abs += collect_files_abs(FPGA_RTL_DIR, {".vhd", ".vhdl"})

    sv_abs   += collect_files_abs(TOP_RTL_DIR,  {".sv"})
    v_abs    += collect_files_abs(TOP_RTL_DIR,  {".v"})
    vhdl_abs += collect_files_abs(TOP_RTL_DIR,  {".vhd", ".vhdl"})

    # Collect memory .data files
    mem_abs = collect_files_abs(MEM_INIT_DIR, {".data"})

    def to_rel_fpga(path_list):
        rels = []
        for p in path_list:
            rel_path = os.path.relpath(p, start=FPGA_DIR)
            rel_path = rel_path.replace("\\", "/")
            rels.append(rel_path)
        return sorted(set(rels))

    xdc_files  = to_rel_fpga(xdc_abs)
    sv_files   = prioritize_pkg_if(to_rel_fpga(sv_abs))
    v_files    = to_rel_fpga(v_abs)
    vhdl_files = to_rel_fpga(vhdl_abs)
    mem_files  = to_rel_fpga(mem_abs)

    header = f"""\
# Copyright (C) 2023  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project details required for generate_bitstream.tcl
# These files are auto-filled by generate_bitstream script.
# If you want to edit search paths or project parameters
# edit add_files_to_tcl file.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name
set project_name {PROJECT_NAME}

# Top module name
set top_module {TOP_MODULE}

# FPGA device
set target {TARGET_FPGA}

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
"""

    def write_section(comment, var_name, files):
        """
        If 'files' is non-empty, produce normal section:
          set var_name {
              path1
              path2
          }

        If empty, produce commented-out example:
          # set var_name {
          #     path/to/something
          # }
        """
        if files:
            s = f"{comment}\nset {var_name} {{\n"
            for fpath in sorted(files):
                s += f"    {fpath}\n"
            s += "}\n\n"
        else:
            s = (f"{comment}\n"
                 f"# set {var_name} {{\n"
                 f"#     path/to/file.data\n"
                 f"# }}\n\n")
        return s

    xdc_section    = write_section("# Specify .xdc files location", "xdc_files", xdc_files)
    sv_section     = write_section("# Specify SystemVerilog design files location", "sv_files", sv_files)
    verilog_section= write_section("# Specify Verilog design files location", "verilog_files", v_files)
    vhdl_section   = write_section("# Specify VHDL design files location", "vhdl_files", vhdl_files)
    mem_section    = write_section("# Specify files for a memory initialization", "mem_files", mem_files)

    new_tcl_content = (header 
                       + xdc_section
                       + sv_section
                       + verilog_section
                       + vhdl_section
                       + mem_section)

    os.makedirs(os.path.dirname(OUTPUT_TCL), exist_ok=True)
    with open(OUTPUT_TCL, "w", encoding="utf-8") as f:
        f.write(new_tcl_content)

    print(colorama.Fore.GREEN + f"[INFO] Updated {OUTPUT_TCL} with new file lists (relative to fpga/).")

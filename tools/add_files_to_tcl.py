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
# Derive key directories based on this script's location:
#   We assume this script is in: <project>/tools/add_files_to_tcl.py
#   Hence PROJECT_DIR is one level above that 'tools' folder.
#   Then we define:
#     - FPGA_DIR            = <project>/fpga
#     - FPGA_CONSTRAINTS_DIR= <project>/fpga/constraints
#     - FPGA_RTL_DIR        = <project>/fpga/rtl
#     - TOP_RTL_DIR         = <project>/rtl
# -------------------------------------------------------------------------
THIS_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR     = os.path.abspath(os.path.join(THIS_SCRIPT_DIR, ".."))
FPGA_DIR        = os.path.join(PROJECT_DIR, "fpga")

FPGA_CONSTRAINTS_DIR = os.path.join(FPGA_DIR, "constraints")  # => ../fpga/constraints
FPGA_RTL_DIR         = os.path.join(FPGA_DIR, "rtl")          # => ../fpga/rtl
TOP_RTL_DIR          = os.path.join(PROJECT_DIR, "rtl")       # => ../rtl

# Where the final TCL gets written (inside fpga/scripts)
OUTPUT_TCL = os.path.join(FPGA_DIR, "scripts", "project_details.tcl")

# -------------------------------------------------------------------------
def collect_files_abs(root_dir, extensions):
    """
    Recursively scan 'root_dir' (absolute path) for files with the given 'extensions',
    returning a sorted list of absolute file paths.
    """
    collected = []
    if not os.path.isdir(root_dir):
        return collected  # If the directory doesn't exist, return empty

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
    Gathers XDC, SV, V, VHDL files from:
      - fpga/constraints
      - fpga/rtl (local)
      - <project>/rtl (parent)
    Then writes them into fpga/scripts/project_details.tcl
    using paths relative to fpga/.
    """

    # --- 1) Collect XDC files from fpga/constraints ---
    xdc_abs = collect_files_abs(FPGA_CONSTRAINTS_DIR, {".xdc"})

    # --- 2) Collect .sv, .v, .vhd from both local (fpga/rtl) and parent (project/rtl) ---
    sv_abs, v_abs, vhdl_abs = [], [], []

    # -- from fpga/rtl --
    sv_abs   += collect_files_abs(FPGA_RTL_DIR, {".sv"})
    v_abs    += collect_files_abs(FPGA_RTL_DIR, {".v"})
    vhdl_abs += collect_files_abs(FPGA_RTL_DIR, {".vhd", ".vhdl"})

    # -- from <project>/rtl --
    sv_abs   += collect_files_abs(TOP_RTL_DIR,  {".sv"})
    v_abs    += collect_files_abs(TOP_RTL_DIR,  {".v"})
    vhdl_abs += collect_files_abs(TOP_RTL_DIR,  {".vhd", ".vhdl"})

    # --- 3) Convert absolute paths to relative paths from fpga/ directory ---
    def to_rel_fpga(path_list):
        rels = []
        for p in path_list:
            rel_path = os.path.relpath(p, start=FPGA_DIR)  # relative to "fpga/"
            # unify to forward slashes:
            rel_path = rel_path.replace("\\", "/")
            rels.append(rel_path)
        return sorted(set(rels))  # remove duplicates, then sort

    xdc_files  = to_rel_fpga(xdc_abs)
    sv_files   = prioritize_pkg_if(to_rel_fpga(sv_abs))
    v_files    = to_rel_fpga(v_abs)
    vhdl_files = to_rel_fpga(vhdl_abs)

    # --- 4) Prepare the new project_details.tcl content ---
    header = f"""\
# Copyright (C) 2023  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name {PROJECT_NAME}

# Top module name                               -- EDIT
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
                 f"#     path/to/file.sv\n"
                 f"# }}\n\n")
        return s

    xdc_section    = write_section("# Specify .xdc files location                   -- EDIT",
                                   "xdc_files", xdc_files)
    sv_section     = write_section("# Specify SystemVerilog design files location   -- EDIT",
                                   "sv_files", sv_files)
    verilog_section= write_section("# Specify Verilog design files location         -- EDIT",
                                   "verilog_files", v_files)
    vhdl_section   = write_section("# Specify VHDL design files location            -- EDIT",
                                   "vhdl_files", vhdl_files)

    mem_section = """\
# Specify files for a memory initialization     -- EDIT
# set mem_files {
#    path/to/file.data
# }
"""

    new_tcl_content = (header 
                       + xdc_section
                       + sv_section
                       + verilog_section
                       + vhdl_section
                       + mem_section)

    # --- 5) Write out the updated TCL file ---
    os.makedirs(os.path.dirname(OUTPUT_TCL), exist_ok=True)
    with open(OUTPUT_TCL, "w", encoding="utf-8") as f:
        f.write(new_tcl_content)

    print(colorama.Fore.GREEN + f"[INFO] Updated {OUTPUT_TCL} with new file lists (relative to fpga/).")

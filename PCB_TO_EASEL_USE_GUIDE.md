# KiCad PCB to Easel (Carvey CNC) Milling Guide

Convert KiCad PCB designs into SVG files for milling on a Carvey CNC using Easel.

## Table of Contents
1. [Overview](#overview)
2. [First-Time Setup](#first-time-setup)
3. [Quick Reference (Repeat Use)](#quick-reference-repeat-use)
4. [Troubleshooting](#troubleshooting)
4. [Command Line Example](#command-line-example)

## Overview

This workflow converts KiCad PCB designs to Easel-compatible SVGs using `pcb2gcode` for isolation routing calculations. The `pcb_to_easel.sh` script handles everything automatically.

**Pipeline:**
```
KiCad → Gerber/Drill Files → pcb2gcode → G-code → SVG → Easel
```

**Output Files:**
`simple_front.svg` Isolation milling paths for copper traces
`simple_drill.svg` Drill holes for components
`simple_outline.svg` Circuit board outline

## First-Time Setup

### 1. Install Homebrew (macOS package manager), skip if you already have this installed

Open Terminal and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, run the commands it displays to add Homebrew to your PATH:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 2. Install pcb2gcode

```bash
brew install pcb2gcode
```

### 3. Verify Installation

```bash
pcb2gcode --version
```

You should see version information (e.g., `pcb2gcode 2.5.0`).

---

## Quick Reference (Repeat Use)

Once setup is complete, use these three steps for each PCB:

### Step 1: Export from KiCad

In KiCad PCB Editor:
1. **File → Plot**
   - Check **F.Cu** (front copper layer)
   - Check **Edge.Cuts** (board outline) — optional but recommended
   - Format: **Gerber**
   - Click **Plot**

2. **File → Fabrication Outputs → Drill Files**
   - Format: **Excellon**
   - Click **Generate Drill File**

You'll have these files in your project folder:
```
YourProject-F_Cu.gbr      # Copper traces
YourProject-Edge_Cuts.gbr # Board outline (optional)
YourProject-PTH.drl       # Drill holes
```
"YourProject" will be replaced by whatever your KiCAD project name is

NOTE: if you prefer to make your board outline in another software like Adobe Illustrator or Inkscape, that is okay, just omit edge cuts from this process. You will get a warning when you run the script that there is no edge cuts file, but don't worry about it. Just make sure you can export the shape of your board outline from whatever software you want to use as an SVG.

### Step 2: Configure & Run Script

1. Copy `pcb_to_easel.sh` to your KiCad project folder (or edit GERBER_DIR)

2. Edit the script to set your file names (lines 29-32):
   ```bash
   GERBER_DIR="$(dirname "$0")"  # Or set to your project path
   FRONT_CU="${GERBER_DIR}/YourProject-F_Cu.gbr"
   EDGE_CUTS="${GERBER_DIR}/YourProject-Edge_Cuts.gbr"
   DRILL_FILE="${GERBER_DIR}/YourProject-PTH.drl"
   ```
   Replace "YourProject" with whatever your KiCAD project name is (the name of your generated gerber and drill files)

   If you want to place pcb_to_easel.sh in a different diectory, set your own directory with something like GERBER_DIR="/Users/yourname/Documents/MyProject" 

   By default the milling diameter (MILL_DIA) is set to 0.24 and the isolation width (ISOLATION_WIDTH) is set to 0.8. These match the bit size and cut depth we use for isolation routing of our PCB traces and pads. To change these numbers would mean we would be using different CNC tooling or changing our cut depth when using V bits.

   There are many other parameters in the script that look as though they are editable and meaningful such as MILL_DEPTH, MILL_FEED, DRILL_SPEED, etc. These are placeholder values that are only there so we can use the pcb2gcode library, and have no impact on the actual milling process on the Carvey. Please do not edit any of these values. 

3. Run:
   ```bash
   chmod +x pcb_to_easel.sh   # First time only
   ./pcb_to_easel.sh
   ```
   this should have created a folder called `gcode/` in the path you set for GERBER_DIR containing svg files for your copper traces (`simple_front.svg`), drill holes (`simple_drill.svg`), and board outline (`simple_outline.svg`)

### Step 3: Import into Easel

See separate Easel tutorial for details

## Troubleshooting

If the script returns: "pcb2gcode: command not found"

Homebrew isn't in your PATH. Run:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

If the script returns: "WARNING: file not found"

Check that:
- File names in script match your actual files (lines 29-31)
- You're running from the correct directory
- Files were exported from KiCad

If traces are too thin after milling

- Ensure Easel cut type is **"On Path"** (not "Outside")
- Check `MILL_DIA` matches your actual bit and milling depth (cut width changed based on depth when using a V bit)

If SVG won't import into Easel

The `simple_*.svg` files are ultra-simple. If import still fails:
1. Open in Inkscape
2. Save as "Plain SVG"
3. Try importing again

---

## Command Line Example

If you place pcb_to_easel.sh in your KiCAD directory

```bash
# 1. Navigate to your KiCad project
cd ~/path/to/your_KiCAD_project

# 2. Copy the script here (or edit GERBER_DIR in the script)
cp ~/path/to/pcb_to_easel.sh .

# 3. Edit the script to match your filenames
nano pcb_to_easel.sh
# Change lines 30-32 to your file names

# 4. Make executable (first time only)
chmod +x pcb_to_easel.sh

# 5. Run
./pcb_to_easel.sh

# 6. Check output
ls #Confirm the expected .svg files are there
```

If you place pcb_to_easel.sh somewhere else

```bash
# 1. Navigate to your KiCad project where your gerrber and drill files are
cd ~/path/to/your_KiCAD_project

# 2. Get full path
pwd #COPY THIS PATH

# 3. Navigate to wherever you placed the pcb_to_easel.sh script
cd
cd ~/path/to/pcb_to_easel.sh

# 4. Edit the script to match your filenames and replace GERBER_DIR with the path you copied from your KiCAD project directory
nano pcb_to_easel.sh
# Change lines 29-32 to your file names and file path

# 5. Make executable (first time only)
chmod +x pcb_to_easel.sh

# 6. Run
./pcb_to_easel.sh

# 7. Check output
cd
cd ~/path/to/your_KiCAD_project/gcode
ls #Confirm the expected .svg files are there
```


*Guide for KiCad → pcb_to_easel.sh → Easel/Carvey PCB milling workflow*
*Last updated: January 2026*

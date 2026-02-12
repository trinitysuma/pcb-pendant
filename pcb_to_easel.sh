#!/bin/bash
# PCB to Easel Conversion Script

# Setup brew environment
eval "$(/opt/homebrew/bin/brew shellenv)"

MILL_DIA="0.24"           # Milling bit diameter (mm)
ISOLATION_WIDTH="0.4"    # Isolation width (at least tool diameter)
CUTTER_DIA="0.8"         # Outline cutter (can use same bit or larger)

# Depths (in mm)
MILL_DEPTH="-0.15"       # Isolation milling depth (into copper + substrate)
DRILL_DEPTH="-2.0"       # Drill through board
CUT_DEPTH="-1.8"         # Board cutout depth
SAFE_Z="2"               # Safe retract height
CHANGE_Z="10"            # Tool change height

# Speeds (mm/min)
MILL_FEED="100"
MILL_SPEED="10000"
DRILL_FEED="50"
DRILL_SPEED="10000"
CUT_FEED="50"
CUT_SPEED="10000"

# Input files (adjust if your files have different names)
GERBER_DIR="/Users/milesscharff/Documents/555timerCES"
FRONT_CU="${GERBER_DIR}/555timerCES-F_Cu.gbr"
EDGE_CUTS="${GERBER_DIR}/555timerCES-Edge_Cuts.gbr"
DRILL_FILE="${GERBER_DIR}/555timerCES-PTH.drl"

# Output directory
OUTPUT_DIR="${GERBER_DIR}/gcode"
mkdir -p "$OUTPUT_DIR"

echo "=== PCB to Easel Conversion ==="
echo "Mill bit: ${MILL_DIA}mm"
echo "Gerber directory: ${GERBER_DIR}"
echo ""

# Check input files exist
for f in "$FRONT_CU" "$EDGE_CUTS" "$DRILL_FILE"; do
    if [ ! -f "$f" ]; then
        echo "WARNING: $f not found"
    fi
done

# Run pcb2gcode
echo "Running pcb2gcode..."
pcb2gcode \
  --front "$FRONT_CU" \
  --outline "$EDGE_CUTS" \
  --drill "$DRILL_FILE" \
  --metric \
  --metricoutput \
  --zwork "$MILL_DEPTH" \
  --zsafe "$SAFE_Z" \
  --mill-feed "$MILL_FEED" \
  --mill-speed "$MILL_SPEED" \
  --mill-diameters "$MILL_DIA" \
  --isolation-width "$ISOLATION_WIDTH" \
  --milling-overlap "50%" \
  --zcut "$CUT_DEPTH" \
  --cut-feed "$CUT_FEED" \
  --cut-speed "$CUT_SPEED" \
  --cutter-diameter "$CUTTER_DIA" \
  --cut-infeed 0.5 \
  --zdrill "$DRILL_DEPTH" \
  --drill-feed "$DRILL_FEED" \
  --drill-speed "$DRILL_SPEED" \
  --bridges 2 \
  --bridgesnum 4 \
  --zbridges -0.5 \
  --zchange "$CHANGE_Z" \
  --output-dir "$OUTPUT_DIR" 2>&1 | grep -v "CRITICAL"

echo ""
echo "Converting to Easel-compatible SVGs..."

# Convert front.ngc to simple SVG
INPUT_FILE="$OUTPUT_DIR/front.ngc" OUTPUT_FILE="$OUTPUT_DIR/simple_front.svg" python3 << 'PYTHON'
import re
import os

def gcode_to_svg(gcode_file, svg_file):
    paths = []
    current_path = []
    x, y, z = 0, 0, 10
    cutting = False
    
    with open(gcode_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('('):
                continue
            
            x_match = re.search(r'X([-\d.]+)', line)
            y_match = re.search(r'Y([-\d.]+)', line)
            z_match = re.search(r'Z([-\d.]+)', line)
            
            new_x, new_y = x, y
            if x_match:
                new_x = float(x_match.group(1))
            if y_match:
                new_y = float(y_match.group(1))
            
            if z_match:
                new_z = float(z_match.group(1))
                if new_z < 0 and z >= 0:
                    cutting = True
                    current_path = [(new_x, new_y)]
                elif new_z >= 0 and z < 0:
                    cutting = False
                    if len(current_path) > 1:
                        paths.append(current_path)
                    current_path = []
                z = new_z
            
            if cutting and (new_x != x or new_y != y):
                current_path.append((new_x, new_y))
            
            x, y = new_x, new_y
    
    if len(current_path) > 1:
        paths.append(current_path)
    
    all_points = [p for path in paths for p in path]
    if not all_points:
        print("  No paths found in front.ngc!")
        return
    
    min_x = min(p[0] for p in all_points)
    max_x = max(p[0] for p in all_points)
    min_y = min(p[1] for p in all_points)
    max_y = max(p[1] for p in all_points)
    
    width = max_x - min_x + 10
    height = max_y - min_y + 10
    
    svg = f'<?xml version="1.0" encoding="UTF-8"?>\n'
    svg += f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.2f}mm" height="{height:.2f}mm" viewBox="{min_x-5:.2f} {-max_y-5:.2f} {width:.2f} {height:.2f}">\n'
    
    for path in paths:
        if len(path) < 2:
            continue
        d = f"M {path[0][0]:.3f} {-path[0][1]:.3f}"
        for p in path[1:]:
            d += f" L {p[0]:.3f} {-p[1]:.3f}"
        svg += f'  <path d="{d}" fill="none" stroke="#000000" stroke-width="0.2"/>\n'
    
    svg += '</svg>\n'
    
    with open(svg_file, 'w') as f:
        f.write(svg)
    
    print(f"  Created {svg_file} ({len(paths)} paths, {len(all_points)} points)")

gcode_to_svg(os.environ['INPUT_FILE'], os.environ['OUTPUT_FILE'])
PYTHON

# Convert drill.ngc to simple SVG with circles
INPUT_FILE="$OUTPUT_DIR/drill.ngc" OUTPUT_FILE="$OUTPUT_DIR/simple_drill.svg" python3 << 'PYTHON'
import re
import os

def drill_to_svg(gcode_file, svg_file):
    holes = []
    current_tool_dia = 0.8
    
    try:
        with open(gcode_file, 'r') as f:
            for line in f:
                line = line.strip()
                
                dia_match = re.search(r'drill size ([\d.]+)mm', line)
                if dia_match:
                    current_tool_dia = float(dia_match.group(1))
                
                g81_match = re.search(r'G81.*X([-\d.]+)\s+Y([-\d.]+)', line)
                if g81_match:
                    x = float(g81_match.group(1))
                    y = float(g81_match.group(2))
                    holes.append((x, y, current_tool_dia))
                    continue
                
                xy_match = re.match(r'^X([-\d.]+)\s+Y([-\d.]+)$', line)
                if xy_match and holes:
                    x = float(xy_match.group(1))
                    y = float(xy_match.group(2))
                    holes.append((x, y, current_tool_dia))
    except FileNotFoundError:
        print("  No drill file found (drill.ngc)")
        return
    
    if not holes:
        print("  No drill holes found in drill.ngc")
        return
    
    min_x = min(h[0] for h in holes) - 5
    max_x = max(h[0] for h in holes) + 5
    min_y = min(h[1] for h in holes) - 5
    max_y = max(h[1] for h in holes) + 5
    
    width = max_x - min_x
    height = max_y - min_y
    
    svg = f'<?xml version="1.0" encoding="UTF-8"?>\n'
    svg += f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.2f}mm" height="{height:.2f}mm" viewBox="{min_x:.2f} {-max_y:.2f} {width:.2f} {height:.2f}">\n'
    
    for x, y, dia in holes:
        r = dia / 2
        svg += f'  <circle cx="{x:.3f}" cy="{-y:.3f}" r="{r:.3f}" fill="none" stroke="#000000" stroke-width="0.1"/>\n'
    
    svg += '</svg>\n'
    
    with open(svg_file, 'w') as f:
        f.write(svg)
    
    print(f"  Created {svg_file} ({len(holes)} holes)")

drill_to_svg(os.environ['INPUT_FILE'], os.environ['OUTPUT_FILE'])
PYTHON

# Convert outline.ngc to simple SVG (FIRST PASS ONLY - avoids duplicate paths)
INPUT_FILE="$OUTPUT_DIR/outline.ngc" OUTPUT_FILE="$OUTPUT_DIR/simple_outline.svg" python3 << 'PYTHON'
import re
import os

def gcode_to_svg(gcode_file, svg_file):
    """
    Extract ONLY the first cutting pass from outline G-code.
    pcb2gcode creates multiple passes at different depths (--cut-infeed),
    which would create overlapping paths that confuse Easel.
    """
    path = []
    x, y, z = 0, 0, 10
    first_plunge_done = False
    capturing = False
    start_x, start_y = None, None
    
    try:
        with open(gcode_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('('):
                    continue
                
                x_match = re.search(r'X([-\d.]+)', line)
                y_match = re.search(r'Y([-\d.]+)', line)
                z_match = re.search(r'Z([-\d.]+)', line)
                
                new_x, new_y = x, y
                if x_match:
                    new_x = float(x_match.group(1))
                if y_match:
                    new_y = float(y_match.group(1))
                
                # Detect first plunge into material
                if z_match:
                    new_z = float(z_match.group(1))
                    if new_z < 0 and z >= 0 and not first_plunge_done:
                        # First time going into material - start capturing
                        first_plunge_done = True
                        capturing = True
                        start_x, start_y = new_x, new_y
                        path = [(new_x, new_y)]
                    z = new_z
                
                # While capturing first pass, record XY moves
                if capturing and (new_x != x or new_y != y):
                    path.append((new_x, new_y))
                    
                    # Check if we've completed the loop (returned to start)
                    if len(path) > 10 and start_x is not None:
                        dist = ((new_x - start_x)**2 + (new_y - start_y)**2)**0.5
                        if dist < 0.1:  # Within 0.1mm of start = closed loop
                            capturing = False  # Stop capturing, we have the outline
                
                x, y = new_x, new_y
                
    except FileNotFoundError:
        print("  No outline file found (outline.ngc)")
        return
    
    # Use just this single path
    paths = [path] if len(path) > 2 else []
    
    all_points = [p for path in paths for p in path]
    if not all_points:
        print("  No outline paths found in outline.ngc")
        return
    
    min_x = min(p[0] for p in all_points)
    max_x = max(p[0] for p in all_points)
    min_y = min(p[1] for p in all_points)
    max_y = max(p[1] for p in all_points)
    
    width = max_x - min_x + 10
    height = max_y - min_y + 10
    
    svg = f'<?xml version="1.0" encoding="UTF-8"?>\n'
    svg += f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.2f}mm" height="{height:.2f}mm" viewBox="{min_x-5:.2f} {-max_y-5:.2f} {width:.2f} {height:.2f}">\n'
    
    for path in paths:
        if len(path) < 2:
            continue
        d = f"M {path[0][0]:.3f} {-path[0][1]:.3f}"
        for p in path[1:]:
            d += f" L {p[0]:.3f} {-p[1]:.3f}"
        svg += f'  <path d="{d}" fill="none" stroke="#000000" stroke-width="0.2"/>\n'
    
    svg += '</svg>\n'
    
    with open(svg_file, 'w') as f:
        f.write(svg)
    
    print(f"  Created {svg_file} ({len(paths)} paths)")

gcode_to_svg(os.environ['INPUT_FILE'], os.environ['OUTPUT_FILE'])
PYTHON

# Clean up the extra SVG files that pcb2gcode generates (we don't need them)
echo ""
echo "Cleaning up pcb2gcode's auto-generated SVGs..."
rm -f "$OUTPUT_DIR"/traced_*.svg
rm -f "$OUTPUT_DIR"/processed_*.svg
rm -f "$OUTPUT_DIR"/original_*.svg
rm -f "$OUTPUT_DIR"/outp*.svg
rm -f "$OUTPUT_DIR"/contentions*.svg

echo ""
echo "=== Done! ==="
echo ""
echo "Output files in: $OUTPUT_DIR"
echo ""
echo "G-Code files (for direct CNC use):"
ls -la "$OUTPUT_DIR"/*.ngc 2>/dev/null
echo ""
echo "SVG files (for Easel import):"
ls -la "$OUTPUT_DIR"/simple*.svg 2>/dev/null
echo ""

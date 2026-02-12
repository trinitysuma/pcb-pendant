# pcb-pendant
This is module 1 of Creative Embedded Systems.

## Materials
This assignment uses the KiCAD files in the 555timerCES folder, a CNC mill, and electrical components (e.g., 3V battery, 3 resistors, 2 capacitors, 1 LED, 1 chip).

## Procedure
### Designing the PCB
Following the PCB schematic given by 555timerCES.kicad_sch, arrange the board in 555timerCES.kicad_pcb such that components can be properly connected. Connect pads by drawing traces between components on the F_Cu layer. Make sure traces are amply spaced to avoid shortages, especially when soldering.

Outline your board on the Edge_Cuts layer using the shape tools. If you'd like to use a custom shape, scale an SVG onto the layer. I used a heart.

### Milling the board
Before beginning the milling process, follow the PCB_TO_EASEL_USE_GUIDE to properly set up the script. Note that it may need to be performed on a Mac. Once set up, run pcb_to_easel to convert your KiCAD files into SVGs. Mine are visible in the svg folder.

Follow this tutorial to mill your board: https://youtu.be/hbWzbn1Lfh0?si=3f0u7-S7WB8Pco6x
You will need three drill bits: 1 V-bit, 1 0.8mm drill bit, and 1 1/8 in straight end bit.

Once the milling is complete, sand down the tabs on your board to your desired shape.

### Building the board
Refer to the original KiCAD schematic and design to place your electrical components. 
You will need:
* 3V battery + holder
* 1 10uF capacitor
* 1 red or yellow LED
* 1 470R resistor
* 1 capacitor of your choosing (I used 4.7uF)
* 2 resistors of your choosing (I used 4.7K and 68K)
To determine the values of your second capacitor and two resistors, reference this site: https://www.allaboutcircuits.com/tools/555-timer-astable-circuit/

Solder your components in place. Use a multimeter to check your connections.

Insert your battery to see the LED flash!

Final product: 

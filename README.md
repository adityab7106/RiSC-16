# risc-16

A VHDL implementation of a basic RiSC-16 CPU on a Basys-3 FPGA.

## File Structure

```text
.
├── docs/
│   ├── Diagrams/
│   │   ├── Main_RTL.png
│   │   └── ...
│   ├── Specs/
│   │   ├── ALU_spec.pdf
│   │   └── ...
│   ├── waveforms/
│   └── report/
│       ├── Final_Project_Report.tex
│       └── images/
├── src/
│   ├── vhdl/
│   │   ├── top_level.vhd
│   │   ├── controller.vhd
│   │   └── ...
│   ├── ip/
│   │   └── memory_ip/
│   └── coe/
│       └── ...
├── tb/
│   ├── top_level_tb.vhd
│   └── ...
└── constraints/
    └── Basys3_Master.xdc

# RiSC-16 CPU

A 16-bit RiSC-16 processor implemented in VHDL on a Xilinx Artix-7 FPGA (Digilent Basys3) and synthesized with Vivado 2024.2. VHDL was primarily used to code the functionalities of the project, which was synthesized with Vivado 2024.2. The design of the processor calls for a multi-cycle architecture, where each instruction executes over a sequence of controller states, leading to a simpler datapath and shorter critical paths. There are seven primary components in the system: a program counter, a combined instruction and data memory implemented as a Block Memory Generator IP, an instruction register, a three-port register file with a hardwired zero register, an arithmetic-logic unit (ALU) that can support operations such as addition, nand, and upper-immediate shifting, a finite-state-machine controller, and a seven-segment display driver that showcases the current value of register seven. There are four multiplexers that appropriately steer the data between components based on the controller's directions. To avoid having to resynthesize the design for each test program, a bootloader is implemented that assembles RISC-16 from a text file and transfers the resulting machine code to the board over the USB-UART link, where a receiver writes it into program memory. A single command handles environment setup, assembly, and upload, and a reset button then clears the display and begins execution.

## Overview

This project implements the RiSC-16 instruction set (as defined by Bruce Jacob). RiSC-16 is a 16-bit reduced instruction set with 8 opcodes (3 bits), eight 16-bit registers, and a uniform word size. Each instruction moves through a controller with a fetch, decode, and execute state.

The design runs at the Basys3's full 100 MHz with no clock division. Most instructions take 4 clock cycles (40 ns), with `lw` requiring 5 clock cycles (50 ns).

To avoid resynthesizing the FPGA design for every test program, the project also includes a bootloader and host-side toolchain that assembles RiSC-16 source and uploads the resulting machine code over USB-UART in seconds.

## Bootloader

Recompiling the FPGA design for every new test program is slow and cumbersome, so a UART-based bootloader and host toolchain make the Basys3 programmable after the initial bitstream is uploaded.

- **`assembler.c`** — a two-pass RiSC-16 assembler (modernized from Bruce Jacob's reference assembler) that turns assembly source into hex machine words
- **`uploader.py`** — a Python script (depends only on `pyserial`) that frames the assembled program into the bootloader's wire protocol and transmits it over serial
- **`upload.ps1`** / **`Makefile`** — drivers for Windows and POSIX-compliant (MacOS/Linux) systems to allow for simple execution of the toolchain

Once the program is done being flashed, execution begins automatically.

### Usage

```
.\upload.ps1                          # uploads program.s, autodetects COM port
.\upload.ps1 -Program test.s -Port COM4
.\upload.ps1 -ListPorts               # list available serial ports
```

The first run compiles the assembler and sets up a Python virtual environment, while later runs only recompile if the source has changed.

## Architecture

Seven primary components make up the system:

- **Program Counter** — holds the address of the instruction being fetched
- **Memory** — a unified instruction/data BRAM (65536 x 16-bit words) generated via the Block Memory Generator IP
- **Instruction Register** — latches the fetched word for the remainder of the instruction
- **Register File** — eight 16-bit registers, three asynchronous read ports, one synchronous write port, with register 0 hardwired to zero
- **ALU** — supports signed addition, bitwise NAND, and the upper-immediate shift used by `lui`
- **Controller** — an eleven-state Moore FSM that sequences fetch/decode/execute and drives every mux select and write enable in the datapath
- **Seven-Segment Display Driver** — continuously displays the value of register 7 as four hex digits

Four multiplexers steer data between components under the controller's direction.

### Instruction formats

- **RRR-type** (`add`, `nand`) — two source registers, one destination
- **RRI-type** (`addi`, `lw`, `sw`, `beq`) — one register plus a 7-bit signed immediate
- **RI-type** (`lui`, `jalr`) — a 10-bit immediate field

A `beq` instruction that branches to itself is appended to every program, freezing the program counter once execution finishes so the result in register 7 stays on the display. Pressing reset clears the display and restarts execution from address 0.

I was responsible for the datapath, designing the program counter, the memory, instruction register, register file, and the ALU.
## Acknowledgements

Thanks to Bruce Jacob for the original RiSC-16 architecture and reference assembler.

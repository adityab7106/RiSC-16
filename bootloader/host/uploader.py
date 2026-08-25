#!/usr/bin/env python3
"""
uploader.py -- send an assembled RiSC-16 program to the Basys-3 bootloader.

Windows-first: run it from PowerShell via upload.ps1, or directly with

    .venv\\Scripts\\python host\\uploader.py program.hex

Wire protocol (must match src/vhdl/bootloader.vhd):
    word 0      : N, the number of 16-bit instruction words that follow
    words 1..N  : the program
Every word goes out big-endian (high byte first), each byte as one 8N1 UART
frame at 115200 baud.
"""

import argparse
import sys
import time
from pathlib import Path

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    sys.exit(
        "pyserial is not installed.\n"
        "  Run:  .venv\\Scripts\\python -m pip install -r requirements.txt\n"
        "  Or:   .\\upload.ps1   (sets the venv up for you)"
    )

BAUD_RATE = 115_200
FTDI_VID = 0x0403           # Basys-3 USB-UART bridge


def list_ports():
    """Every serial port the OS can see, most-likely-Basys-3 first."""
    ports = list(serial.tools.list_ports.comports())
    ports.sort(key=lambda p: (p.vid != FTDI_VID, p.device))
    return ports


def describe(p):
    return f"  {p.device:<8} {p.description or '(no description)'}"


def find_board(explicit=None):
    """Pick the Basys-3's COM port, or explain why we can't."""
    ports = list_ports()

    if explicit:
        if any(p.device.upper() == explicit.upper() for p in ports):
            return explicit
        print(f"Port {explicit} not found. Ports currently present:")
        for p in ports:
            print(describe(p))
        sys.exit(1)

    candidates = [p for p in ports if p.vid == FTDI_VID]

    if len(candidates) == 1:
        return candidates[0].device

    if not candidates:
        print("No Basys-3 detected (looking for an FTDI device, VID 0403).")
        print("Check that the board is powered on and the USB cable is in the PROG port.")
        if ports:
            print("Ports currently present:")
            for p in ports:
                print(describe(p))
        else:
            print("No serial ports present at all.")
        sys.exit(1)

    print("More than one FTDI device found -- pick one with --port:")
    for p in candidates:
        print(describe(p))
    sys.exit(1)


def read_hex(path):
    """Parse the assembler's output: one 4-digit hex word per line."""
    words = []
    for lineno, raw in enumerate(Path(path).read_text().splitlines(), start=1):
        line = raw.split("#")[0].split("//")[0].strip()
        if not line:
            continue
        try:
            value = int(line, 16)
        except ValueError:
            sys.exit(f"{path}:{lineno}: not a hex word: {raw.strip()!r}")
        if not 0 <= value <= 0xFFFF:
            sys.exit(f"{path}:{lineno}: does not fit in 16 bits: {raw.strip()!r}")
        words.append(value)

    if not words:
        sys.exit(f"{path}: no instructions found")
    if len(words) > 0xFFFF:
        sys.exit(f"{path}: {len(words)} words is more than the 16-bit count field holds")
    return words


def build_payload(words):
    payload = bytearray(len(words).to_bytes(2, "big"))     # header: word count
    for w in words:
        payload += w.to_bytes(2, "big")                    # then the program
    return bytes(payload)


def main():
    ap = argparse.ArgumentParser(description="Upload a program to the RiSC-16 bootloader.")
    ap.add_argument("hexfile", nargs="?", default="program.hex",
                    help="assembler output (default: program.hex)")
    ap.add_argument("--port", help="COM port to use, e.g. COM3 (default: autodetect)")
    ap.add_argument("--baud", type=int, default=BAUD_RATE,
                    help=f"baud rate (default: {BAUD_RATE}; must match the VHDL generic)")
    ap.add_argument("--list", action="store_true", help="list serial ports and exit")
    ap.add_argument("--dry-run", action="store_true",
                    help="build and print the payload without opening a port")
    args = ap.parse_args()

    if args.list:
        ports = list_ports()
        if not ports:
            print("No serial ports found.")
        else:
            print("Serial ports:")
            for p in ports:
                print(describe(p) + ("   <-- likely the Basys-3" if p.vid == FTDI_VID else ""))
        return 0

    if not Path(args.hexfile).exists():
        sys.exit(f"{args.hexfile} not found. Assemble first, or run .\\upload.ps1")

    words = read_hex(args.hexfile)
    payload = build_payload(words)

    print(f"{args.hexfile}: {len(words)} instruction words")
    preview = payload[:16].hex(" ")
    print(f"payload: {len(payload)} bytes  [{preview}{' ...' if len(payload) > 16 else ''}]")

    if args.dry_run:
        print("dry run -- nothing sent")
        return 0

    port = find_board(args.port)
    print(f"opening {port} at {args.baud} baud")

    try:
        with serial.Serial(port, args.baud, timeout=1.0, write_timeout=5.0) as ser:
            time.sleep(0.1)                 # let the FTDI settle after open
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            sent = ser.write(payload)
            ser.flush()
            time.sleep(0.1)                 # let the last frames clock out

    except PermissionError:
        sys.exit(
            f"{port} is busy -- Windows only lets one program hold a COM port.\n"
            "Close Vivado's Hardware Manager, PuTTY, Tera Term, or any other\n"
            "serial monitor, then run this again."
        )
    except serial.SerialException as e:
        sys.exit(f"serial error on {port}: {e}")

    print(f"sent {sent} bytes ({len(words)} instructions + 1 header word)")
    print("the board should be running now; the display switches from the")
    print("word count to register 7 once the load finishes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
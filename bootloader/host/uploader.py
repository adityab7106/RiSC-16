import serial
import serial.tools.list_ports
import time
import sys
import os

BAUD_RATE = 115200
TIMEOUT = 1.0

def find_basys3_port():
    """Dynamically detects the Basys 3 USB-UART serial port."""
    ports = list(serial.tools.list_ports.comports())
    
    # Priority 1: Match standard Digilent/FTDI hardware descriptions or VID/PID
    for p in ports:
        desc = (p.description or "").lower()
        mfg = (p.manufacturer or "").lower()
        if "ftdi" in desc or "digilent" in desc or "ftdi" in mfg or "digilent" in mfg:
            return p.device
        if p.vid == 0x0403:  # Standard FTDI Vendor ID
            return p.device

    # Priority 2: Fallback to common OS device naming patterns
    for p in ports:
        dev = p.device.lower()
        if "usbserial" in dev or "ttyusb" in dev:
            return p.device

    return None

# Check CLI arguments
if len(sys.argv) != 2:
    print("Usage: python uploader.py <filename.hex>")
    sys.exit(1)

hex_file = sys.argv[1]

if not os.path.exists(hex_file):
    print(f"Error: File '{hex_file}' not found.")
    sys.exit(1)

# Parse instructions
instructions = bytearray()
try:
    with open(hex_file, "r") as f:
        for line in f:
            clean_line = line.strip()
            if clean_line:
                val = int(clean_line, 16)
                instructions.extend(val.to_bytes(2, byteorder='big'))
except ValueError:
    print(f"Error: Could not parse '{hex_file}'. Must contain valid 4-character hex strings.")
    sys.exit(1)

# Calculate length header (word count)
word_count = len(instructions) // 2
header = word_count.to_bytes(2, byteorder='big')
payload = header + instructions

# Display assembly stats
print(f"Generated Hex: {hex_file} ({word_count} instructions)")
print(f"Prepared Payload: {payload.hex(' ')}")

# Attempt upload
PORT = find_basys3_port()
if not PORT:
    available = [p.device for p in serial.tools.list_ports.comports()]
    print("\n[Warning] Basys 3 board not detected via USB.")
    print(f"Available ports: {available if available else 'None'}")
    print("Skipping UART upload. Plug in the board and run 'make upload' to send.")
    sys.exit(0)  # Exit cleanly with 0 so Make does not flag an Error 1

try:
    print(f"\nDetected Basys 3 at: {PORT}")
    print(f"Connecting at {BAUD_RATE} baud...")
    with serial.Serial(PORT, BAUD_RATE, timeout=TIMEOUT) as ser:
        time.sleep(0.1)
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        bytes_sent = ser.write(payload)
        ser.flush()

        print(f"Success! Sent {bytes_sent} bytes total ({word_count} instructions + 1 header word).")

except serial.SerialException as e:
    print(f"Serial error: {e}")
    sys.exit(1)

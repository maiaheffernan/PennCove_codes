"""
rbr_concerto_burst.py

Configures burst sampling on an RBR Concerto via RS-232 serial communication
on macOS. Commands match the Logger2 Command Reference (RBR0001963revB).

Burst plan: 10 samples per burst, one burst every 5 minutes.

Key parameters (all times in milliseconds):
  period        = time between samples WITHIN a burst
  burstlength   = number of samples per burst
  burstinterval = time between the START of consecutive bursts

Constraint the logger enforces before enabling:
  burstinterval > (burstlength * period)
  e.g. 300000 > (10 * 100) = 1000  ✓
"""

# Before running the script, find your Concerto's port name in the Terminal:
#   ls /dev/tty.*
# Then update the PORT variable below with the correct name (e.g. /dev/tty.usbserial-XXXX).

import serial
import time

# ─── Configuration ────────────────────────────────────────────────────────────
PORT        = "/dev/tty.usbserial-XXXX"  # Replace with your port (run: ls /dev/tty.*)
BAUD_RATE   = 9600                        # Default RBR baud rate
TIMEOUT     = 2                           # Seconds to wait for a response

# Deployment schedule — edit these to match your deployment window
START_TIME  = "20250501000000"   # YYYYMMDDhhmmss
END_TIME    = "20250601000000"   # YYYYMMDDhhmmss

# Burst sampling parameters
PERIOD_MS        = 100      # Time between samples within each burst (ms)
BURST_LENGTH     = 10       # Number of samples per burst
BURST_INTERVAL   = 300000   # Time between burst starts = 5 min (ms)
# ──────────────────────────────────────────────────────────────────────────────


def send_command(ser, command):
    """Send a command to the RBR instrument and return the response."""
    full_command = command + "\r\n"
    ser.write(full_command.encode("ascii"))
    time.sleep(0.3)
    response = ser.read_all().decode("ascii", errors="ignore").strip()
    print(f"  >> {command}")
    print(f"  << {response}")
    print()
    return response


def main():
    print("=" * 55)
    print("  RBR Concerto — Burst Sampling Configuration Script")
    print("  Commands per Logger2 Command Reference (revB)")
    print("=" * 55)
    print()

    try:
        ser = serial.Serial(
            port=PORT,
            baudrate=BAUD_RATE,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=TIMEOUT
        )
        print(f"Connected to {PORT} at {BAUD_RATE} baud.\n")

        # ── Step 1: Wake the instrument ──────────────────────────────────────
        # Send a single CR to wake from sleep, then pause per the manual.
        print("Step 1: Waking instrument...")
        ser.write(b"\r")
        time.sleep(0.1)    # 10ms minimum per manual; 100ms is safer
        ser.read_all()     # Discard any garbage characters from wakeup
        print("  Instrument awake.\n")

        # ── Step 2: Confirm communication ────────────────────────────────────
        # 'id' is the recommended first command after wakeup (per manual).
        print("Step 2: Confirming communication with 'id'...")
        send_command(ser, "id")

        # ── Step 3: Stop any ongoing sampling ────────────────────────────────
        # The manual uses 'stop' (not 'disable') for compatibility.
        print("Step 3: Stopping any active sampling...")
        send_command(ser, "stop")

        # ── Step 4: Set start and end times ──────────────────────────────────
        print(f"Step 4: Setting start time to {START_TIME}...")
        send_command(ser, f"starttime = {START_TIME}")

        print(f"Step 5: Setting end time to {END_TIME}...")
        send_command(ser, f"endtime = {END_TIME}")

        # ── Step 6: Configure burst sampling in one command ──────────────────
        # Per the manual, mode, period, burstlength, and burstinterval can all
        # be set in a single 'sampling' command. Units are always milliseconds.
        # Constraint: burstinterval > (burstlength * period)
        #   300000 > (10 * 100) = 1000  ✓
        print("Step 6: Configuring burst sampling...")
        sampling_cmd = (
            f"sampling mode = burst, "
            f"period = {PERIOD_MS}, "
            f"burstlength = {BURST_LENGTH}, "
            f"burstinterval = {BURST_INTERVAL}"
        )
        send_command(ser, sampling_cmd)

        # ── Step 7: Verify the schedule (dry run of enable) ──────────────────
        # 'verify' runs all the same checks as 'enable' but does not start
        # logging. It also checks that memory is empty.
        print("Step 7: Verifying schedule (dry run)...")
        verify_response = send_command(ser, "verify")

        if "E04" in verify_response:
            print("  [!] Verify returned an error. Check the response above.")
            print("  Common fix: memory may not be empty — enable with erasememory = true.")
        else:
            print("  Schedule looks valid.")

        # ── Step 8: Enable the instrument ────────────────────────────────────
        # Uncomment when you're ready to actually start the deployment.
        # 'erasememory = true' clears memory and enables in one step.
        #
        # print("Step 8: Enabling the instrument...")
        # send_command(ser, "enable erasememory = true")
        #
        # After enabling, check status:
        # send_command(ser, "status")

        print("\n✓ Configuration complete.")
        print("  Review responses above, then uncomment 'enable' to start logging.\n")

        ser.close()
        print("Serial connection closed.")

    except serial.SerialException as e:
        print(f"\n[ERROR] Could not connect to {PORT}.")
        print(f"  Details: {e}")
        print(f"  Tip: run 'ls /dev/tty.*' in Terminal to find your port name.")


if __name__ == "__main__":
    main()
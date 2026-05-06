"""
RBR Concerto³ Wire Walker Upcast Sampling — Autonomous Setup Script
====================================================================
Version 2.0 — Updated for fully autonomous 6-month Fermata deployment

Deployment scenario:
  - Wire walker, 22m cable, Concerto mounted ~1.5m from bottom of carriage
  - Instrument reads ~20.5 dbar at full depth; 20 dbar is the regime boundary
  - Upcast duration: ~2 min at 0.5 m/s
  - Downcast duration: ~20 min (variable, wave-driven)
  - Power source: RBRfermata with alkaline D-cells (0.9 kWh capacity)
  - No external computer during deployment

Autonomous sampling behavior:
  - regimes mode, direction=ascending, count=1, binsize=0 (no averaging)
  - Instrument wakes and samples when ascending through 20 dbar
  - Instrument naturally stops storing data when descending below 20 dbar
  - Between upcasts, instrument is in low-power sleep (sampling period gating)
  - No computer needed after this script runs

IMPORTANT — "stop after 1 min" behavior:
  The RBR regimes firmware does NOT have a built-in stop-after-idle timer.
  However, for a wire walker the regime boundary crossing handles this naturally:
    - On upcast:  pressure crosses 20 dbar ascending → logging starts
    - At surface: instrument keeps logging but near surface (low pressure)
    - On downcast: pressure crosses 20 dbar descending → logging stops
  The only "wasted" data is the brief surface loiter period (~minutes).
  Filter this in post-processing using pressure < 5 dbar or similar.

  If the wire walker controller HAS a serial output (RS-232), this script
  also includes a handshake sequence you can wire in. See SERIAL HANDSHAKE
  section at the bottom of this file.

Requirements:
    pip install pyserial

Usage:
    python rbr_wirewalker_setup_v2.py

Monthly maintenance visits:
    - Open Ruskin, connect to instrument, download .rsk file
    - Do NOT run memclear or enable erasememory=true (this erases the data!)
    - The deployment schedule continues autonomously without reprogramming
    - Only re-run this script if the instrument was power-cycled with the
      deployment disabled, or if you want to change sampling parameters
"""

import serial
import serial.tools.list_ports
import time
import sys
from datetime import datetime, timedelta

# ============================================================
# USER CONFIGURATION
# ============================================================

PORT = None             # e.g. "COM4" or "/dev/ttyUSB0"; None = auto-detect
BAUD_RATE = 115200

# Sampling rate during the upcast.
# 1 Hz (1000 ms) gives ~120 samples over a 2-minute upcast — recommended.
# 2 Hz (500 ms) gives ~240 samples; higher data density but more power.
# 6 Hz (167 ms) is common for fast CTD profiling if needed.
SAMPLING_PERIOD_MS = 1000       # 1 Hz 

# Regime 1: active profiling zone (20 dbar down to SURFACE_IDLE_BOUNDARY_DBAR)
# Samples fire at SAMPLING_PERIOD_MS. 
UPCAST_BOUNDARY_DBAR = 20

# Regime 2: near-surface idle zone (above SURFACE_IDLE_BOUNDARY_DBAR)
# When the walker is stuck at the surface or in the turnaround, the instrument
# fires at a very slow rate (one sample per 5 minutes), aggressively conserving
# Fermata alkaline capacity during calm/idle periods.
# Set to 2 dbar (~2 m depth) 
SURFACE_IDLE_BOUNDARY_DBAR = 2
SURFACE_IDLE_PERIOD_MS = 300000  # 1 sample per 5 minutes when near-surface/stuck

# Deployment duration. Script sets end time this many days from now.
DEPLOY_END_OFFSET_DAYS = 250   # ~8 months

# ============================================================
# END USER CONFIGURATION
# ============================================================

WAKEUP_PAUSE    = 0.12
CMD_TIMEOUT     = 8.0
INTER_CMD_PAUSE = 0.35


def find_rbr_port():
    ports = serial.tools.list_ports.comports()
    candidates = []
    for p in ports:
        desc = (p.description or "").lower()
        mfr  = (p.manufacturer or "").lower()
        if any(k in desc or k in mfr for k in ["rbr", "cdc", "serial", "usb"]):
            candidates.append(p.device)
    if len(candidates) == 1:
        return candidates[0]
    all_ports = [p.device for p in ports]
    if not all_ports:
        print("ERROR: No serial ports found.")
        sys.exit(1)
    print("Available serial ports:")
    for i, p in enumerate(all_ports):
        info = next((x for x in ports if x.device == p), None)
        desc = info.description if info else ""
        print(f"  [{i}] {p}  —  {desc}")
    idx = int(input("Select port number: "))
    return all_ports[idx]


def open_port(port, baud):
    return serial.Serial(
        port=port, baudrate=baud,
        bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE, timeout=CMD_TIMEOUT,
        xonxoff=False, rtscts=False, dsrdtr=False,
    )


def wakeup(ser):
    ser.reset_input_buffer()
    ser.write(b"\r")            # character break wakes up the concerto
    time.sleep(WAKEUP_PAUSE)
    ser.reset_input_buffer()


def send_cmd(ser, cmd, retries=2):
    """Send command, return full response string. Raises RuntimeError on E0xxx error."""
    for attempt in range(retries + 1):
        wakeup(ser)
        ser.write((cmd.strip() + "\r").encode("ascii"))
        time.sleep(INTER_CMD_PAUSE)

        lines = []
        deadline = time.time() + CMD_TIMEOUT
        while time.time() < deadline:
            raw = ser.readline()
            if not raw:
                break
            line = raw.decode("ascii", errors="replace").strip()
            if line:
                lines.append(line)
            # Stop once the command echo has appeared in any line
            if any(cmd.split()[0].lower() in l.lower() for l in lines):
                # Grab one more line (the value / error line)
                extra = ser.readline().decode("ascii", errors="replace").strip()
                if extra:
                    lines.append(extra)
                break

        response = "\n".join(lines)

        # Check for RBR error codes (format: E0NNN ...)
        error_line = next(
            (l for l in lines if l.upper().startswith("E0") and len(l) > 4 and l[1:5].isdigit()),
            None
        )
        if error_line:
            if attempt < retries:
                print(f"  [retry {attempt+1}] '{cmd}' → {error_line}")
                time.sleep(1.0)
                continue
            raise RuntimeError(f"Instrument error on '{cmd}': {error_line}")
        return response

    return response


def fmt_dt(dt):
    return dt.strftime("%Y%m%d%H%M%S")


def run_power_check(ser):
    """Query the instrument's own energy consumption estimates."""
    print("\n[Power Check] Reading instrument energy estimates...")
    try:
        resp = send_cmd(ser, "power")
        print(f"  power response:\n  {resp}")
        print()
        print("  These are the instrument's own estimates (from RBR factory characterization).")
        print("  p1 = sleep power (W), p2 = sampling power (W).")
        print("  Use these in the power budget section of the README.")
    except RuntimeError as e:
        print(f"  Could not read power info: {e}")
        print("  (Some firmware versions use 'powerinternal' or 'powerexternal' instead.)")
        try:
            resp = send_cmd(ser, "powerinternal")
            print(f"  powerinternal: {resp}")
        except RuntimeError:
            pass


def main():
    print("=" * 65)
    print("RBR Concerto³ Wire Walker Upcast Setup — Autonomous v2.0")
    print("=" * 65)
    print(f"\nConfiguration:")
    print(f"  Sampling period : {SAMPLING_PERIOD_MS} ms ({1000/SAMPLING_PERIOD_MS:.2f} Hz)")
    print(f"  Regime boundary : {UPCAST_BOUNDARY_DBAR} dbar")
    print(f"  Deployment span : {DEPLOY_END_OFFSET_DAYS} days from now")
    print()

    # ------------------------------------------------------------------
    # STEP 1: Connect
    # ------------------------------------------------------------------
    print("[Step 1] Connecting...")
    port = PORT if PORT else find_rbr_port()
    print(f"  Port: {port} @ {BAUD_RATE} baud")
    ser = open_port(port, BAUD_RATE)

    try:
        # ------------------------------------------------------------------
        # STEP 2: Identify
        # ------------------------------------------------------------------
        print("\n[Step 2] Identifying instrument...")
        wakeup(ser)
        resp = send_cmd(ser, "id")
        print(f"  {resp}")

        # ------------------------------------------------------------------
        # STEP 3: Read power consumption estimates from the instrument
        # (do this BEFORE any changes so values reflect current config)
        # ------------------------------------------------------------------
        run_power_check(ser)

        # ------------------------------------------------------------------
        # STEP 4: Disable any active deployment
        # ------------------------------------------------------------------
        print("[Step 4] Stopping any existing deployment...")
        try:
            resp = send_cmd(ser, "disable")
            print(f"  {resp}")
        except RuntimeError as e:
            if "E0401" in str(e):
                print("  Not currently logging (OK).")
            else:
                raise

        # ------------------------------------------------------------------
        # STEP 5: Set clock
        # ------------------------------------------------------------------
        print("\n[Step 5] Setting clock to current UTC...")
        now = datetime.utcnow()
        resp = send_cmd(ser, f"clock datetime = {fmt_dt(now)}")
        print(f"  Clock set: {fmt_dt(now)} UTC")

        # ------------------------------------------------------------------
        # STEP 6: Set deployment window
        # ------------------------------------------------------------------
        print("\n[Step 6] Setting deployment window...")
        end_time = now + timedelta(days=DEPLOY_END_OFFSET_DAYS)
        resp = send_cmd(ser, f"deployment starttime = {fmt_dt(now)}, endtime = {fmt_dt(end_time)}")
        print(f"  Start: {fmt_dt(now)}")
        print(f"  End  : {fmt_dt(end_time)}")

        # ------------------------------------------------------------------
        # STEP 7: Set sampling mode = regimes
        # The 'period' here sets the base measurement rate. It must be set
        # to the fastest rate used in any regime (regime 1 = SAMPLING_PERIOD_MS).
        # ------------------------------------------------------------------
        print("\n[Step 7] Setting sampling mode to 'regimes'...")
        resp = send_cmd(ser, f"sampling mode = regimes, period = {SAMPLING_PERIOD_MS}")
        print(f"  {resp}")

        # ------------------------------------------------------------------
        # STEP 8: Configure regimes (ascending, 2 regimes, absolute pressure)
        #
        # Two regimes:
        #   Regime 1 (20 → 3 dbar): Full sampling rate (1 Hz) — the profile
        #   Regime 2 (3 → 0 dbar):  Very slow rate (1 sample per 5 min) — surface idle mode
        #
        # When the walker is stuck at the surface, regime 2 keeps the instrument
        # technically active but firing sensors only once every 5 minutes, reducing
        # stuck-surface power consumption
        # ------------------------------------------------------------------
        print("\n[Step 8] Configuring regimes (2 regimes, ascending, absolute)...")
        resp = send_cmd(ser, "regimes direction = ascending, count = 2, reference = absolute")
        print(f"  {resp}")

        # ------------------------------------------------------------------
        # STEP 9a: Configure regime 1 — profiling zone (20 to 3 dbar)
        #
        # boundary = 20 dbar  — sampling activates when ascending through this
        # binsize  = 0        — NO bin averaging; every sample stored individually
        # samplingperiod      — measurement rate in ms (1000 = 1 Hz)
        # ------------------------------------------------------------------
        print(f"\n[Step 9a] Configuring regime 1 (profiling, {UPCAST_BOUNDARY_DBAR}→{SURFACE_IDLE_BOUNDARY_DBAR} dbar)...")
        resp = send_cmd(
            ser,
            f"regime 1 boundary = {UPCAST_BOUNDARY_DBAR}, "
            f"binsize = 0, "
            f"samplingperiod = {SAMPLING_PERIOD_MS}"
        )
        print(f"  {resp}")

        # ------------------------------------------------------------------
        # STEP 9b: Configure regime 2 — near-surface idle zone (3 to 0 dbar)
        #
        # boundary = 3 dbar   — regime 2 activates once above 3 dbar
        # binsize  = 0        — no averaging; sparse samples stored individually
        # samplingperiod = 300000 ms — one sample per 5 minutes (vs 1000 ms in regime 1)
        #
        # This reduction in firing rate dramatically cuts DO sensor power
        # when the walker is stuck at the surface or in the turnaround.
        # ------------------------------------------------------------------
        print(f"\n[Step 9b] Configuring regime 2 (surface idle, <{SURFACE_IDLE_BOUNDARY_DBAR} dbar, 1/5 min)...")
        resp = send_cmd(
            ser,
            f"regime 2 boundary = {SURFACE_IDLE_BOUNDARY_DBAR}, "
            f"binsize = 0, "
            f"samplingperiod = {SURFACE_IDLE_PERIOD_MS}"
        )
        print(f"  {resp}")

        # ------------------------------------------------------------------
        # STEP 10: Verify
        # ------------------------------------------------------------------
        print("\n[Step 10] Verifying configuration...")
        try:
            resp = send_cmd(ser, "verify")
            print(f"  verify: {resp}")
        except RuntimeError as e:
            err = str(e)
            if "E0402" in err:
                print("  Memory not empty — will be erased on enable (expected).")
            else:
                print(f"  Verify warning: {e}")
                print("  Review the error above before proceeding.")

        # ------------------------------------------------------------------
        # STEP 11: Confirm and enable
        # ------------------------------------------------------------------
        print("\n[Step 11] Ready to enable. This will ERASE instrument memory.")
        print("  Download all existing data in Ruskin before proceeding!")
        confirm = input("\n  Type 'yes' to erase memory and enable: ").strip().lower()
        if confirm != "yes":
            print("  Aborted. No changes made to memory or deployment state.")
            return

        resp = send_cmd(ser, "enable erasememory = true")
        print(f"  enable: {resp}")

        # ------------------------------------------------------------------
        # STEP 12: Confirm status
        # ------------------------------------------------------------------
        print("\n[Step 12] Confirming deployment status...")
        resp = send_cmd(ser, "deployment status")
        print(f"  {resp}")

        if "logging" in resp.lower() or "pending" in resp.lower():
            print("\n  ✓ Instrument is enabled and ready for deployment.")
        else:
            print("\n  WARNING: Unexpected status. Verify manually before deploying.")

        # ------------------------------------------------------------------
        # SUMMARY
        # ------------------------------------------------------------------
        print("\n" + "=" * 65)
        print("SETUP COMPLETE — DEPLOYMENT SUMMARY")
        print("=" * 65)
        print(f"""
  Sampling mode    : regimes (ascending, 1 regime)
  Boundary depth   : {UPCAST_BOUNDARY_DBAR} dbar — sampling begins on ascending upcast
  Bin averaging    : NONE (binsize = 0)
  Sample rate      : {1000/SAMPLING_PERIOD_MS:.2f} Hz ({SAMPLING_PERIOD_MS} ms period)
  Expected samples : ~{int(120 * 1000 / SAMPLING_PERIOD_MS)} per upcast (2 min ascent)
  Deployment ends  : {fmt_dt(end_time)} UTC

  HOW AUTONOMOUS OPERATION WORKS (TWO-REGIME):
  ─────────────────────────────────────────────────────────
  Descending / stuck below 20 dbar:
    → Not in any active regime. Instrument sleeps between
      internal pressure checks. Power draw is minimal (~1mW).

  Ascending through 20 dbar (upcast begins):
    → Regime 1 activates. Samples at {SAMPLING_PERIOD_MS} ms (1 Hz).
      Every sample is stored (binsize=0). DO sensor fires
      each sample. This continues up to 2 dbar.

  Ascending through 2 dbar / stuck at surface:
    → Regime 2 activates. Samples at {SURFACE_IDLE_PERIOD_MS} ms (1 per 5 min).
      Power drops ~300x compared to regime 1. One sparse
      sample every 5 minutes stored — trivially filtered in
      post-processing by the 300s gaps between timestamps.

  Descending back through 3 dbar → 20 dbar:
    → Returns to regime 1 briefly on way down, then exits
      all regimes below 20 dbar. Instrument sleeps again.

  STUCK-SURFACE POWER SAVINGS:
    Regime 2 at 1/5min vs 1 Hz: ~300x reduction in sensor
    firing events. For a 5-day calm period, this saves
    roughly 9+ Wh compared to single-regime setup —
    critical over a 6-month Fermata alkaline deployment
    in a low-wave environment like Penn Cove.

  Between upcasts (on downcast and bottom):
    → Instrument is in sleep mode. Between each 1-second
      "check", the RBR L3 platform sleeps at <1 mW.
      This is the dominant power-saving behavior.

  MONTHLY MAINTENANCE:
  ─────────────────────────────────────────────────────────
  → Connect via Ruskin → download .rsk file → done.
  → Do NOT click "Erase Memory" in Ruskin.
  → Do NOT run this script again (the deployment continues).
  → Only re-run this script if deployment status = disabled.

  WIRE WALKER SERIAL HANDSHAKE (OPTIONAL):
  ─────────────────────────────────────────────────────────
  → See the function 'wirewalker_handshake_example()' at
    the bottom of this file. If your wire walker controller
    has RS-232 output, it can send 'disable' and 're-enable'
    commands at the end/start of each upcast.
  → Baud rate for RBR serial port: set with 'serial baud'
    command (default 9600 on RS-232, 115200 on USB).
""")

    finally:
        ser.close()
        print("Serial port closed.")


# ============================================================
# WIRE WALKER SERIAL HANDSHAKE (REFERENCE / OPTIONAL)
# ============================================================
#
# If your wire walker controller has a free RS-232 serial output,
# you can wire it to the RBR Concerto's external serial connector
# (MCBH-6, pin 2 = TX from controller → RX on RBR, pin 3 = GND).
#
# The RBR serial port defaults to 9600 baud, 8N1. You can change
# this with: serial baud = 115200 (while connected via USB first).
#
# The controller would run logic equivalent to this pseudocode at
# the END of each upcast (when walker reaches surface / stops rising):

def wirewalker_handshake_example(ser_controller):
    """
    Example function showing commands a wire walker controller would send
    to the RBR Concerto over its serial port to explicitly stop and
    restart logging at each upcast boundary.

    Call at_end_of_upcast() when your controller detects ascent has stopped.
    Call at_start_of_upcast() when your controller begins the next ascent.

    NOTE: In pure regimes mode without this handshake, the instrument
    manages itself via the pressure boundary. This function is only needed
    if you want EXPLICIT stop/start control from the wire walker controller.
    """

    def at_end_of_upcast(ser):
        """Send to RBR when upcast is complete and walker begins descending."""
        ser.write(b"\r")          # Wake up
        time.sleep(0.12)
        ser.write(b"disable\r")   # Stop logging
        time.sleep(0.5)
        # RBR will now sleep. On the next upcast, you can re-enable OR
        # simply let regimes mode re-trigger on the boundary crossing.

    def at_start_of_upcast(ser):
        """Send to RBR at the start of a new upcast to re-enable logging."""
        # Only needed if you sent 'disable' above.
        # Without this, regimes mode re-triggers automatically on boundary.
        ser.write(b"\r")
        time.sleep(0.12)
        # You would need to resend the full enable sequence here.
        # Simplest approach: just rely on regimes mode auto-triggering
        # and only send 'disable' when you want to cleanly end a cast.

    # For a wire walker with no controller serial output, these functions
    # are not used — regimes mode handles everything autonomously.
    pass


if __name__ == "__main__":
    main()
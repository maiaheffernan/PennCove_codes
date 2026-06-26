# This script pulls MET data from a station near Penn Cove in the Coupeville Naval Outlying Field (Coordinates: Approx. 48.202°N, 122.627°W). 
# If you are curious, this location is used primarily for Field Carrier Landing Practice, where pilots simulate aircraft carrier landings on a
# land-based runway marked to replicate a carrier deck. This training prepares crews for night and day carrier operations, particularly for  
# aircraft such as the EA-18G Growler and P-8A Poseidon. Its MET station data can be found here: https://www.weather.gov/wrh/timeseries
# plot=wind_speedgust&site=KNRA


# My primary reason for using this is to determine what the wind speeds were for the PEnn Cove area in 2025 for the months of May-October. I am trying to see if the wind is consistently 1-3knots because the Wire Walker will supposedly walk when winds are this strong. I am trying to decide what sampling configuration to use with the Concertos on the wire walker and I want an idea of how long the Germata battery will last. Ruskin determines battery life based on a 60% duty cycle for sampling, but I have a feeling that the wire walker is not going to walk that much so the concerto might not sample quickly all the time (it samples quickly on the upcasts starting at 20m and then samples slowly once it reaches 2m below the surface), so the battery might extend longer than it says (right now it puts the battery at 114 days).

# Maia with the help of ChatGPT, May 2026

import pandas as pd
import requests
from io import StringIO
import matplotlib.pyplot as plt

# ==========================================================
# CONFIG
# ==========================================================

STATION = "NRA"   # Coupeville OLF
OUTPUT_FILE = "penncove_open_wind_2025.csv"
MONTHLY_OUTPUT = "monthly_avg_wind_2025.csv"

URL = "https://mesonet.agron.iastate.edu/cgi-bin/request/asos.py"

# ==========================================================
# REQUEST DATA
# ==========================================================

params = {
    "station": STATION,
    "data": [
        "tmpf",
        "dwpf",
        "drct",
        "sknt",
        "gust",
        "mslp",
        "alti",
    ],
    "year1": 2025,
    "month1": 5,
    "day1": 1,
    "year2": 2025,
    "month2": 10,
    "day2": 31,
    "tz": "Etc/UTC",
    "format": "onlycomma",
    "latlon": "no",
    "elev": "no",
    "missing": "M",
    "trace": "T",
    "direct": "yes",
    "report_type": "3",
}

print("Downloading data...")

response = requests.get(URL, params=params, timeout=60)

if response.status_code != 200:
    raise Exception(f"HTTP ERROR: {response.status_code}")

print("Parsing CSV...")

df = pd.read_csv(StringIO(response.text))

# ==========================================================
# CLEAN COLUMNS
# ==========================================================

df = df.rename(columns={
    "valid": "timestamp_utc",
    "drct": "wind_direction_deg",
    "sknt": "wind_speed_knots",
    "gust": "wind_gust_knots",
    "tmpf": "temperature_f",
    "dwpf": "dewpoint_f",
    "mslp": "sea_level_pressure_mb",
    "alti": "altimeter_inhg",
})

# Convert timestamps
df["timestamp_utc"] = pd.to_datetime(df["timestamp_utc"])

# Convert wind speed to numeric
df["wind_speed_knots"] = pd.to_numeric(
    df["wind_speed_knots"],
    errors="coerce"
)

df["wind_gust_knots"] = pd.to_numeric(
    df["wind_gust_knots"],
    errors="coerce"
)

# Convert knots -> mph
df["wind_speed_mph"] = df["wind_speed_knots"] * 1.15078
df["wind_gust_mph"] = df["wind_gust_knots"] * 1.15078

# Add month name
df["month"] = df["timestamp_utc"].dt.strftime("%B")

# ==========================================================
# SAVE RAW CSV
# ==========================================================

df.to_csv(OUTPUT_FILE, index=False)

print(f"Saved raw data to: {OUTPUT_FILE}")

# ==========================================================
# MONTHLY AVERAGE WIND SPEED (KNOTS)
# ==========================================================

monthly_avg = (
    df.groupby("month")["wind_speed_knots"]
    .mean()
    .reset_index()
)

# Preserve calendar order
month_order = [
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
]

monthly_avg["month"] = pd.Categorical(
    monthly_avg["month"],
    categories=month_order,
    ordered=True
)

monthly_avg = monthly_avg.sort_values("month")

# Save averages
monthly_avg.to_csv(MONTHLY_OUTPUT, index=False)

print("\nAverage Wind Speed By Month (knots)")
print("-----------------------------------")

for _, row in monthly_avg.iterrows():
    print(f"{row['month']:10s}: {row['wind_speed_knots']:.2f} knots")

print(f"\nSaved monthly averages to: {MONTHLY_OUTPUT}")

# ==========================================================
# PLOT TIME SERIES
# ==========================================================

plt.figure(figsize=(14, 6))

plt.plot(
    df["timestamp_utc"],
    df["wind_speed_knots"],
    linewidth=0.6
)

plt.title("Penn Cove Area Wind Speed (May-Oct 2025)")
plt.xlabel("Date")
plt.ylabel("Wind Speed (knots)")

plt.grid(True, alpha=0.3)

plt.tight_layout()

# Save figure
plot_file = "wind_speed_timeseries_2025.png"

plt.savefig(plot_file, dpi=300)

print(f"Saved plot to: {plot_file}")

plt.show()

# GPS Test - RaceBox BLE GPS Display

An iOS app built with Swift and SwiftUI that connects to an ESP32 RaceBox emulator via Bluetooth Low Energy (BLE) to display real-time GPS coordinates, motion data, and IMU (accelerometer/gyroscope) readings with advanced features including performance timing, min/max tracking, and configurable units.

## Features

### Core Features
- **BLE Connection**: Automatically scans and connects to RaceBox Mini devices
- **High-Frequency GPS**: Receives GPS data at 25 Hz refresh rate
- **Tab-Based Navigation**: Modern tab interface with Dashboard, Min/Max, Timing, and Settings views

### Dashboard
- **GPS Position**: Latitude, longitude (7 decimal precision), altitude, satellite count
- **GPS Quality Indicators**: Fix status (No Fix/2D/3D), PDOP, update rate (Hz)
- **Motion Data**: Speed and heading with configurable units
- **IMU Data**: 3-axis accelerometer (g-force) and gyroscope (rotation rate) with calibration support
- **Battery Status**: Real-time battery level and charging status
- **Real-time Updates**: Live data refresh rate indicator
- **Recording Indicator**: Shows when recording active with live stats
  - Pulsing red dot when recording
  - Sample count, duration, and distance
  - Quick stop button

### Min/Max Tracking
- **Track Peak Values**: Monitor maximum speed, altitude range, and G-forces
- **Session Management**: Save and view historical min/max sessions
- **Detailed G-Force Analysis**: Track min/max for all three axes (X, Y, Z)
- **Acceleration/Deceleration**: Monitor peak forward and braking forces

### Performance Timing
- **All 11 Metrics**: Display complete performance analysis
  - Distance: 60ft, 1/8 mile, 1/4 mile  
  - Acceleration: 0-30, 0-40, 0-60, 0-80, 0-100 mph
  - Rolling: 30-70, 40-100 mph
  - Braking: 60-0 mph
- **Session Recording**: Start/stop recording for automatic metric calculation
- **Reliability Indicators**: Shows accuracy warnings for unreliable data
- **Auto-compute**: Metrics calculated immediately upon stopping recording
- **Real-time Monitoring**: Live speed, distance, and sample count during recording

### Session Management
- **Dedicated Sessions Tab**: View and manage all recorded sessions
- **Session List**: Shows date, duration, sample count, distance, and max speed
- **Session Detail View**: 
  - Complete session metadata
  - Compute and view all 11 performance metrics
  - Reliability indicators for each metric
  - Export functionality
- **Swipe to Delete**: Easily remove individual sessions
- **Storage Management**: View count and clear all sessions with confirmation

### Settings
- **Connection Management**: Connect/disconnect from RaceBox device
- **Speed Units**: Choose between m/s, kph, mph, or knots
- **Altitude Units**: Select meters or feet
- **Sensor Calibration**: 
  - Zero G-force sensors while stationary
  - Zero gyroscope for drift compensation
  - Reset calibration to defaults
- **Accelerometer Orientation**: Auto-detect device mounting position
- **Recording Settings**:
  - Sample rate display (25 Hz from RaceBox)
  - Accuracy threshold slider (10-100m)
- **Session Storage**: View session count and clear all with confirmation
- **Settings Persistence**: All preferences saved automatically

### UI/UX
- **Modern Design**: Clean, card-based interface with subtle shadows
- **Dark Mode Support**: Fully adaptive to system appearance
- **Smooth Animations**: Pulse animations on connection status, transitions on timing
- **Color-Coded Status**: Visual indicators for connection, GPS fix, and battery level
- **Icons**: SF Symbols throughout for intuitive navigation

## Requirements

- iOS 14.0+
- Xcode 15.0+
- ESP32 RaceBox Mini Emulator (see [ESP32-RaceBox-mini-Emulator](https://github.com/dandol328/ESP32-RaceBox-mini-Emulator))
- Bluetooth permissions enabled

## BLE Protocol Details

The app implements the RaceBox Mini BLE protocol:

- **Service UUID**: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **TX Characteristic UUID**: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- **Data Format**: 88-byte packet containing GPS and IMU data
- **Update Rate**: 25 Hz

### GPS Data Packet Structure

The app parses the following fields from the 88-byte packet:

| Field | Absolute Offset | Type | Description |
|-------|-----------------|------|-------------|
| Header | 0-1 | uint16 | Frame start (0xB5 0x62) |
| Message Class | 2 | uint8 | 0xFF for RaceBox Data Message |
| Message ID | 3 | uint8 | 0x01 for live GPS data |
| Fix Status | 26 | uint8 | 0=no fix, 2=2D, 3=3D |
| Fix Status Flags | 27 | uint8 | Bit 0: valid fix |
| Num Satellites | 29 | uint8 | Number of satellites tracked |
| Longitude | 30-33 | int32 | Longitude in degrees × 10^7 |
| Latitude | 34-37 | int32 | Latitude in degrees × 10^7 |
| Altitude | 38-41 | int32 | Height above ellipsoid in mm |
| Speed | 54-57 | int32 | Ground speed in mm/s |
| Heading | 58-61 | int32 | Heading of motion in degrees × 10^5 |
| PDOP | 70-71 | uint16 | Position dilution of precision × 100 |
| Battery Status | 73 | uint8 | MSB: charging, lower 7 bits: percentage |
| Accelerometer X | 74-75 | int16 | milli-g (forward/back) |
| Accelerometer Y | 76-77 | int16 | milli-g (left/right) |
| Accelerometer Z | 78-79 | int16 | milli-g (up/down) |
| Gyroscope X | 80-81 | int16 | centi-degrees/sec (roll) |
| Gyroscope Y | 82-83 | int16 | centi-degrees/sec (pitch) |
| Gyroscope Z | 84-85 | int16 | centi-degrees/sec (yaw) |

## Usage

1. **Build and Run**: Open the project in Xcode and run it on a physical iOS device (BLE doesn't work in the simulator)

2. **Connect to RaceBox**: 
   - Navigate to the Settings tab
   - Tap the "Connect to RaceBox" button
   - The app will automatically scan for and connect to any device named "RaceBox Mini"

3. **View Data**:
   - **Dashboard Tab**: View all real-time GPS and sensor data
   - **Min/Max Tab**: Track and save peak performance values
   - **Timing Tab**: Start recording sessions and view all 11 performance metrics
   - **Sessions Tab**: View, manage, and export all recorded sessions
   - **Settings Tab**: Configure units, calibrate sensors, manage storage

4. **Configure Units**:
   - Go to Settings tab
   - Choose your preferred speed unit (m/s, kph, mph, knots)
   - Choose your preferred altitude unit (meters, feet)

5. **Calibrate Sensors**:
   - Place device on a level, stationary surface
   - Go to Settings tab
   - Tap "Zero G-Force" to calibrate accelerometer
   - Tap "Zero Gyroscope" to calibrate gyroscope

6. **Track Min/Max**:
   - Navigate to Min/Max tab
   - Values automatically update as you drive
   - Tap "Save Session" to log current session
   - Tap "Reset" to start fresh tracking

7. **Performance Timing**:
   - Navigate to Timing tab
   - Ensure GPS has a good fix (3D)
   - Tap "Start Recording" when ready
   - Perform your run (acceleration, braking, etc.)
   - Tap "Stop Recording" to end session
   - Metrics are automatically calculated and displayed
   - Session is saved to Sessions tab for later review

8. **Manage Sessions**:
   - Navigate to Sessions tab
   - View all recorded sessions with metadata
   - Tap a session to view details
   - Compute metrics on-demand
   - Export in JSON, CSV, GPX, or KML format
   - Swipe left to delete individual sessions
   - Use menu to clear all sessions

## Code Structure

```
GPS Test/
├── GPS_TestApp.swift           # Main app entry point
├── ContentView.swift            # Tab navigation and Dashboard UI
├── BLEManager.swift            # BLE handling and GPS data parsing
├── UserSettings.swift          # Settings persistence and unit conversions
├── SettingsView.swift          # Settings interface
├── MinMaxView.swift            # Min/Max tracking interface
├── PerformanceTimingView.swift # Performance timing and recording interface
├── SessionsView.swift          # Session list view
├── SessionDetailView.swift     # Session detail and export view
├── Models/                     # Data models
│   ├── LocationSample.swift
│   ├── RecordingSession.swift
│   ├── FixType.swift
│   └── MetricResult.swift
├── Managers/                   # Business logic
│   └── SessionManager.swift
├── Metrics/                    # Performance calculations
│   └── MetricsEngine.swift
├── Export/                     # Export formats
│   ├── SessionExporter.swift
│   ├── JSONExportFormat.swift
│   ├── CSVExporter.swift
│   ├── GPXExporter.swift
│   └── KMLExporter.swift
└── Assets.xcassets/            # App assets
```

### BLEManager.swift

The `BLEManager` class handles all Bluetooth operations:

- **Scanning**: Discovers RaceBox devices advertising the correct service UUID
- **Connection**: Establishes and manages BLE connection
- **Data Reception**: Subscribes to TX characteristic notifications
- **Parsing**: Extracts GPS position, motion, IMU data, fix status, battery, and PDOP
- **Update Rate Tracking**: Calculates real-time data refresh rate
- **State Management**: Publishes connection status and all sensor data to the UI

### UserSettings.swift

The `UserSettings` class manages app configuration:

- **Unit Conversion**: Handles speed (m/s, kph, mph, knots) and altitude (m, ft) conversions
- **Calibration**: Stores and applies sensor zero offsets
- **Persistence**: Uses @AppStorage for automatic settings persistence

### UI Components

The app provides multiple specialized views:

- **DashboardView**: Comprehensive real-time data display with status indicators
- **MinMaxView**: Track and log peak performance metrics
- **PerformanceTimingView**: Dedicated timing interface for acceleration and distance runs
- **SettingsView**: Configuration and calibration controls

## Permissions

The app requires Bluetooth permissions, which are configured in the project settings:

- `NSBluetoothAlwaysUsageDescription`: "This app uses Bluetooth to connect to the ESP32 RaceBox emulator and receive GPS data at 25Hz."
- `NSBluetoothPeripheralUsageDescription`: "This app uses Bluetooth to connect to the ESP32 RaceBox emulator and receive GPS data at 25Hz."

Users will be prompted to grant Bluetooth access when they first launch the app.

## Troubleshooting

**App doesn't find the RaceBox device:**
- Ensure the ESP32 is powered on and advertising
- Check that the device name starts with "RaceBox" (e.g., "RaceBox Mini", "RaceBox Pro")
- Verify Bluetooth is enabled on your iPhone

**Connection drops frequently:**
- Keep the iPhone close to the ESP32 (within 10 meters)
- Avoid obstacles between devices
- Check that the ESP32 is receiving adequate power

**GPS coordinates show 0.0:**
- Wait for the ESP32 to acquire GPS fix (may take 30-60 seconds outdoors)
- Ensure the ESP32 has a clear view of the sky
- Check that the GPS antenna is properly connected
- Look for "3D Fix" status on the Dashboard

**Timing runs not starting:**
- Ensure you have a GPS connection
- Wait for "3D Fix" status before starting
- Make sure device is connected (check Settings tab)

**G-force or gyroscope readings seem off:**
- Calibrate sensors while device is stationary and level
- Go to Settings → "Zero G-Force" and "Zero Gyroscope"
- If issues persist, tap "Reset All Calibration"

## Hardware Setup

For hardware assembly and ESP32 firmware setup, see the [ESP32 RaceBox Mini Emulator Repository](https://github.com/dandol328/ESP32-RaceBox-mini-Emulator).

Required components:
- ESP32 Development Board
- U-blox GNSS Module (SAM-M10Q or similar)
- MPU6050 IMU (optional, but included in the protocol)

## License

This project is independent and open-source. It is compatible with the RaceBox Mini protocol but is not affiliated with, endorsed by, or officially connected to RaceBox.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Enhanced Data Model

The app uses a comprehensive `LocationSample` data structure to capture all GNSS and accuracy information:

### LocationSample Fields

```json
{
  "id": "uuid",
  "latitude": 37.123456,
  "longitude": -122.123456,
  "altitude": 5.2,
  "timestamp": "2026-01-19T12:00:00Z",
  "horizontalAccuracy": 2.5,
  "verticalAccuracy": 3.0,
  "speed": 12.5,
  "speedAccuracy": 0.2,
  "heading": 120.0,
  "headingAccuracy": 5.0,
  "fixType": "threeD",
  "ageOfFix": 0.1,
  "satellites": 12,
  "hdop": 0.9,
  "vdop": 1.2,
  "pdop": 1.5
}
```

**Core Position Data:**
- `latitude`, `longitude`: Position in decimal degrees (7 decimal precision)
- `altitude`: Height above ellipsoid in meters
- `timestamp`: ISO 8601 timestamp with millisecond precision

**Accuracy Metrics:**
- `horizontalAccuracy`: GPS horizontal accuracy in meters
- `verticalAccuracy`: GPS vertical accuracy in meters
- `speedAccuracy`: Speed measurement accuracy in m/s
- `headingAccuracy`: Heading measurement accuracy in degrees

**Motion Data:**
- `speed`: Ground speed in m/s
- `heading`: Direction of motion (0-360 degrees, 0 = North)

**GNSS Quality Indicators:**
- `fixType`: Fix quality enum - `noFix`, `twoD`, `threeD`, `dgps`, `rtk`, `unknown`
- `satellites`: Number of satellites tracked
- `hdop`: Horizontal Dilution of Precision (lower is better, <2 excellent)
- `vdop`: Vertical Dilution of Precision
- `pdop`: Position Dilution of Precision (3D accuracy, <2 excellent)
- `ageOfFix`: Time in seconds since last fix update

## Session Recording

The app supports high-frequency GPS session recording with full data capture:

**Recording Features:**
- **Sample Rate**: Configurable 1-25 Hz (default: 25 Hz max for RaceBox)
- **Data Storage**: All LocationSample fields captured with full precision
- **Session Metadata**: UUID, name, tags, notes, start/end times
- **Automatic Persistence**: Sessions saved to local storage
- **Export Formats**: JSON, CSV, GPX, KML

**RecordingSession Structure:**
```swift
{
  "id": "uuid",
  "startTime": "ISO 8601 timestamp",
  "endTime": "ISO 8601 timestamp",
  "sampleRateHz": 25,
  "name": "Session name",
  "tags": ["tag1", "tag2"],
  "notes": "Session notes"
}
```

## Comprehensive Performance Metrics

The app calculates **11 different performance metrics** automatically from recorded sessions:

### Distance-Based Metrics
- **60 Feet** (18.288m): Quarter-mile tree to 60ft mark - ET and trap speed
- **1/8 Mile** (201.168m): Eighth-mile drag racing - ET and trap speed  
- **1/4 Mile** (402.336m): Quarter-mile drag racing - ET and trap speed

### Speed-Based Acceleration Metrics
- **0-30 mph**: Elapsed time and distance to reach 30 mph
- **0-40 mph**: Elapsed time and distance to reach 40 mph
- **0-60 mph**: Elapsed time and distance to reach 60 mph
- **0-80 mph**: Elapsed time and distance to reach 80 mph
- **0-100 mph**: Elapsed time and distance to reach 100 mph

### Rolling Speed Intervals
- **30-70 mph**: Passing acceleration time and distance
- **40-100 mph**: Highway passing acceleration time and distance

### Braking Metrics
- **60-0 mph**: Braking time and **stopping distance** from 60 mph to full stop

### Metric Data Fields

Each metric includes:
- `elapsedTime`: Time to complete metric (seconds)
- `trapSpeed`: Speed at end of metric (m/s) - for distance-based and speed-based
- `peakSpeed`: Maximum speed achieved during metric (m/s)
- `distance`: Total distance traveled during metric (meters)
- `startDistance`: Cumulative distance at metric start (meters)
- `startTimestamp`: When metric started
- `endTimestamp`: When metric completed/threshold reached
- `avgHorizontalAccuracy`: Average GPS accuracy during metric (meters)
- `sampleCount`: Number of GPS samples used in calculation
- `isReliable`: Boolean indicator based on accuracy threshold (default: 50m)

## Metric Calculation Algorithm

The app uses advanced algorithms for accurate performance measurement:

### Distance Calculation
- **Haversine Formula**: Calculates great-circle distance between GPS coordinates
- Accounts for Earth's curvature (WGS84 ellipsoid)
- Accurate for distances from centimeters to thousands of kilometers
- Cumulative distance tracking throughout session

### Threshold Detection
- **Linear Interpolation**: Precise detection of exact moment thresholds are crossed
- Interpolates between GPS samples for sub-sample precision
- Example: If sample at 59.5 mph and next at 60.5 mph, calculates exact 60 mph timestamp
- Applied to both speed and distance thresholds

### Start Detection
- Automatic motion detection at **2 mph (0.894 m/s) threshold**
- Filters out GPS drift and stationary noise
- Metrics begin from first movement above threshold

### Data Quality Indicators
- **Accuracy Threshold**: Default 50 meters horizontal accuracy
- Samples exceeding threshold flagged in metrics
- `isReliable` flag set based on average accuracy
- `avgHorizontalAccuracy` reported for transparency
- Higher sample rates (25 Hz) improve interpolation accuracy

## Data Export

Sessions can be exported in multiple industry-standard formats:

### JSON Export
- Complete session data with all fields
- Includes samples array with full LocationSample objects
- MetricsSummary with all calculated metrics
- Human-readable and machine-parseable
- See `examples/example-session.json`

### CSV Export
- Header with session metadata and metrics summary
- One row per GPS sample
- Columns: timestamp, lat/lon, altitude, speed, heading, all accuracy fields
- Compatible with Excel, Google Sheets, data analysis tools
- See `examples/example-session.csv`

### GPX Export
- Standard GPS Exchange Format (GPX 1.1)
- Compatible with mapping software (Google Earth, Basecamp, Strava)
- Track points include elevation, speed, timestamp
- Extensions for accuracy data

### KML Export
- Google Earth visualization format
- Track displayed as path with placemarks
- Color-coded by speed or accuracy
- Session metadata in description

**Export Location**: All formats available in `examples/` directory

## Accelerometer Orientation Detection

The app features intelligent accelerometer orientation detection for accurate G-force measurement:

### Auto-Detection
- **Automatic Axis Detection**: Identifies which accelerometer axis points forward during acceleration
- **Trigger**: Detect orientation while accelerating (speed > 2 mph / 0.894 m/s)
- **Supported Mountings**: Works with any device mounting position
- **Axis Mapping**: Maps device X/Y/Z axes to vehicle Forward/Right/Up axes

### Manual Control
- **Reset to Default**: Return to standard orientation (X=forward, Y=right, Z=up)
- **Status Display**: Shows current detected orientation mapping
- **Persistent**: Orientation saved in user settings

### How It Works
1. During acceleration, call "Detect Orientation" in Settings
2. App analyzes X, Y, Z accelerometer readings
3. Identifies axis with strongest forward acceleration
4. Determines sign (positive/negative) of forward direction
5. Maps remaining axes using right-hand rule
6. All subsequent G-force displays use vehicle-relative axes

**Benefits:**
- Mount device in any position (portrait, landscape, upside-down)
- Accurate forward/lateral/vertical G-force display
- No manual configuration needed

## Configuration Options

The app provides configurable parameters for customization:

### Sample Rate
- **Range**: 1-25 Hz
- **Default**: 25 Hz (maximum supported by RaceBox)
- **Use Cases**: Lower rates save storage, higher rates improve interpolation accuracy

### Accuracy Threshold
- **Default**: 50 meters horizontal accuracy
- **Purpose**: Filter unreliable GPS data
- **Effect**: Sets `isReliable` flag on metrics

### Unit Conversions

**Speed Units:**
- Meters per second (m/s)
- Kilometers per hour (kph)
- Miles per hour (mph)
- Knots (kt)

**Altitude Units:**
- Meters (m)
- Feet (ft)

**Settings Persistence**: All preferences automatically saved via `@AppStorage`

## JSON Schema Example

Complete LocationSample structure in exported JSON:

```json
{
  "session": {
    "id": "12345678-1234-1234-1234-123456789012",
    "startTime": "2026-01-19T12:00:00Z",
    "endTime": "2026-01-19T12:01:30Z",
    "sampleRateHz": 25,
    "name": "Example Performance Run",
    "tags": ["test", "0-60", "quarter-mile"],
    "notes": "Synthetic example session"
  },
  "samples": [
    {
      "id": "sample-001",
      "latitude": 37.123456,
      "longitude": -122.123456,
      "altitude": 5.2,
      "timestamp": "2026-01-19T12:00:00Z",
      "horizontalAccuracy": 2.5,
      "verticalAccuracy": 3.0,
      "speed": 0.0,
      "speedAccuracy": 0.2,
      "heading": 120.0,
      "headingAccuracy": 5.0,
      "fixType": "threeD",
      "ageOfFix": 0.1,
      "satellites": 12,
      "hdop": 0.9,
      "vdop": 1.2,
      "pdop": 1.5
    }
  ],
  "metrics": {
    "sessionId": "12345678-1234-1234-1234-123456789012",
    "computedAt": "2026-01-19T12:02:00Z",
    "accuracyThreshold": 50.0,
    "useFilteredData": false,
    "results": [
      {
        "id": "metric-001",
        "metricType": "60ft",
        "elapsedTime": 2.456,
        "startTimestamp": "2026-01-19T12:00:00Z",
        "endTimestamp": "2026-01-19T12:00:02.456Z",
        "trapSpeed": 12.5,
        "peakSpeed": 12.5,
        "distance": 18.288,
        "startDistance": 0.0,
        "avgHorizontalAccuracy": 2.4,
        "sampleCount": 62,
        "isReliable": true
      }
    ]
  }
}
```

## Usage Examples

### Start/Stop Recording Sessions

1. **Navigate to Recording View**
2. **Tap "Start Recording"** - begins capturing GPS samples at configured rate
3. **Perform your run** - acceleration, braking, circuit lap, etc.
4. **Tap "Stop Recording"** - ends session and saves to storage
5. **Add metadata** - name, tags, notes (optional)

### Export Session Data

1. **Select a saved session** from session list
2. **Tap "Export"** button
3. **Choose format**: JSON, CSV, GPX, or KML
4. **Share** via AirDrop, email, Files app, or other apps

### Detect Accelerometer Orientation

1. **Go to Settings tab**
2. **Find "Accelerometer Orientation" section**
3. **During forward acceleration** (>2 mph):
   - Tap "Detect Orientation" button
   - App analyzes current G-forces
   - Displays detected mapping
4. **Status shows**: "Detected: Forward=+X, Right=+Y, Up=+Z" (or your configuration)
5. **To reset**: Tap "Reset to Default Orientation"

### View Metrics for a Session

1. **Open a saved session** from session list
2. **View Metrics Summary**:
   - Distance-based: 60ft, 1/8 mile, 1/4 mile times
   - Speed-based: 0-30, 0-60, 0-100 mph times
   - Rolling: 30-70, 40-100 mph times
   - Braking: 60-0 mph time and distance
3. **Check reliability**: Green checkmark = reliable, amber = low accuracy
4. **Details include**: ET, trap speed, distance, accuracy, sample count

## Changelog

### Version 2.1.0 - Full Integration Complete ✅
- **Session Management Tab**: Added dedicated Sessions tab for viewing all recorded sessions
- **Enhanced Session Detail View**: View comprehensive session metadata and compute all 11 metrics
- **Improved Export UI**: Polished export interface with individual format buttons and batch export
- **Recording Indicator**: Live recording indicator on Dashboard showing sample count, duration, and distance
- **Quick Stop**: Added quick stop button to recording indicator
- **Configurable Settings**: 
  - Accuracy threshold slider (10-100m) for metric reliability
  - Sample rate display (25 Hz from RaceBox)
  - Session storage management with count display
  - Clear all sessions with confirmation
- **Error Handling**: User-facing alerts for export failures
- **Updated PerformanceTimingView**: 
  - Removed old PerformanceTimer class
  - Now uses SessionManager for recording
  - Displays all 11 metrics with reliability indicators
  - Auto-computes metrics on stop
- **Code Quality**: 
  - No hard-coded values - all configurable via settings
  - Proper error handling throughout
  - Thread-safe metric computation
  - Memory-safe with no retain cycles

### Version 2.0.0
- Added comprehensive LocationSample data model with all GNSS accuracy fields
- Added session recording with configurable 1-25 Hz sample rate
- Added 11 performance metrics (60ft, 1/8mi, 1/4mi, 0-30/40/60/80/100, 30-70, 40-100, 60-0)
- Added Haversine distance calculation with linear interpolation
- Added data export in JSON, CSV, GPX, and KML formats
- Added accelerometer orientation auto-detection for any mounting position
- Added accuracy threshold configuration (default 50m)
- Added reliability indicators on all metrics
- Added example export files in examples/ directory

### Version 1.1.0
- Added Min/Max tracking with session saving
- Added Performance timing (0-60, 1/8 mile, 1/4 mile)
- Added Settings page with connection controls
- Added configurable units (speed: m/s, kph, mph, knots; altitude: m, ft)
- Added sensor calibration (G-force and gyroscope zeroing)
- Added fix status, PDOP, battery level, and update rate displays
- Improved UI with modern design, animations, and dark mode support
- Moved connection controls to Settings tab
- Added tab-based navigation

### Version 1.0.0
- Initial release with basic GPS and IMU data display

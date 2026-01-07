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

### Min/Max Tracking
- **Track Peak Values**: Monitor maximum speed, altitude range, and G-forces
- **Session Management**: Save and view historical min/max sessions
- **Detailed G-Force Analysis**: Track min/max for all three axes (X, Y, Z)
- **Acceleration/Deceleration**: Monitor peak forward and braking forces

### Performance Timing
- **0-60 Timer**: Measure 0-60 mph or kph acceleration time
- **1/8 Mile**: Time and trap speed for 1/8 mile runs
- **1/4 Mile**: Time and trap speed for 1/4 mile runs
- **Best Times**: Automatically save and display personal best times
- **Real-time Monitoring**: Live speed and distance tracking during runs

### Settings
- **Connection Management**: Connect/disconnect from RaceBox device
- **Speed Units**: Choose between m/s, kph, mph, or knots
- **Altitude Units**: Select meters or feet
- **Sensor Calibration**: 
  - Zero G-force sensors while stationary
  - Zero gyroscope for drift compensation
  - Reset calibration to defaults
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
   - **Timing Tab**: Perform acceleration and distance timing runs
   - **Settings Tab**: Configure units and calibrate sensors

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
   - Tap "Start" when ready
   - Accelerate from standstill
   - Times are automatically recorded and displayed
   - Best times are saved and highlighted

## Code Structure

```
GPS Test/
├── GPS_TestApp.swift           # Main app entry point
├── ContentView.swift            # Tab navigation and Dashboard UI
├── BLEManager.swift            # BLE handling and GPS data parsing
├── UserSettings.swift          # Settings persistence and unit conversions
├── SettingsView.swift          # Settings interface
├── MinMaxView.swift            # Min/Max tracking interface
├── PerformanceTimingView.swift # Performance timing interface
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

## Changelog

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

# GPS Test - RaceBox BLE GPS Display

An iOS app built with Swift and SwiftUI that connects to an ESP32 RaceBox emulator via Bluetooth Low Energy (BLE) to display real-time GPS coordinates.

## Features

- **BLE Connection**: Automatically scans and connects to RaceBox Mini devices
- **High-Frequency GPS**: Receives GPS data at 25 Hz refresh rate
- **Real-time Display**: Shows latitude and longitude with 7 decimal precision
- **Clean UI**: Modern SwiftUI interface with connection status indicator
- **Auto-reconnect**: Handles disconnections gracefully

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

| Field | Offset | Type | Description |
|-------|--------|------|-------------|
| Header | 0-1 | uint16 | Frame start (0xB5 0x62) |
| Message Class | 2 | uint8 | 0xFF for RaceBox Data Message |
| Message ID | 3 | uint8 | 0x01 for live GPS data |
| Longitude | 30-33 | int32 | Longitude in degrees × 10^7 |
| Latitude | 34-37 | int32 | Latitude in degrees × 10^7 |

## Usage

1. **Build and Run**: Open the project in Xcode and run it on a physical iOS device (BLE doesn't work in the simulator)

2. **Connect to RaceBox**: 
   - Ensure your ESP32 RaceBox emulator is powered on and advertising
   - Tap the "Connect" button in the app
   - The app will automatically scan for and connect to any device named "RaceBox Mini"

3. **View GPS Data**:
   - Once connected, latitude and longitude will update at 25 Hz
   - The status indicator shows the connection state (green = connected, red = disconnected)

4. **Disconnect**: Tap the "Disconnect" button to end the BLE connection

## Code Structure

```
GPS Test/
├── GPS_TestApp.swift      # Main app entry point
├── ContentView.swift      # UI layer with GPS display
├── BLEManager.swift       # BLE handling and GPS data parsing
└── Assets.xcassets/       # App assets
```

### BLEManager.swift

The `BLEManager` class handles all Bluetooth operations:

- **Scanning**: Discovers RaceBox devices advertising the correct service UUID
- **Connection**: Establishes and manages BLE connection
- **Data Reception**: Subscribes to TX characteristic notifications
- **Parsing**: Extracts latitude and longitude from the 88-byte packet
- **State Management**: Publishes connection status and GPS coordinates to the UI

### ContentView.swift

The SwiftUI view provides:

- Real-time latitude/longitude display
- Connection status indicator
- Connect/Disconnect buttons
- Responsive layout for iPhone and iPad

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

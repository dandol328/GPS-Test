# GPS Test App - Development Guide

## Architecture Overview

The GPS Test app has been enhanced with comprehensive GNSS telemetry, performance metrics, data export, and advanced sensor orientation features.

### Core Components

#### 1. Data Models (`GPS Test/Models/`)

**FixType.swift**
- Enumeration for GNSS fix types: noFix, twoD, threeD, dgps, rtk, unknown
- Converts from BLE fix status values to semantic types

**LocationSample.swift**
- Comprehensive location sample with 15+ fields:
  - Position: latitude, longitude, altitude, timestamp
  - Accuracy: horizontalAccuracy, verticalAccuracy, speedAccuracy, headingAccuracy
  - Motion: speed, heading
  - GNSS Quality: fixType, satellites, hdop, vdop, pdop, ageOfFix
- `fromBLE()` factory method estimates accuracy fields from PDOP
- Fully Codable for JSON export

**RecordingSession.swift**
- Container for GPS samples with metadata
- Fields: id, startTime, endTime, samples[], name, tags, notes, sampleRateHz
- Computed properties: duration, totalDistance, maxSpeed, avgSpeed
- Haversine distance calculation between samples
- Codable for persistence

**MetricResult.swift**
- Performance metric result with timing, speed, and distance data
- MetricType enum: 11 metric types (distance, speed, rolling, braking)
- Fields: elapsedTime, trapSpeed, peakSpeed, distance, accuracy metrics
- MetricsSummary aggregates all results for a session

#### 2. Session Management (`GPS Test/Managers/`)

**SessionManager.swift**
- Observable class managing recording sessions
- Start/stop recording with configurable sample rate (max 25 Hz)
- Add samples during recording
- Persistent storage via UserDefaults (JSON encoding)
- Keeps most recent 50 sessions

#### 3. Metrics Engine (`GPS Test/Metrics/`)

**MetricsEngine.swift** (780+ lines)
- Computes all 11 performance metrics from LocationSample data
- Key algorithms:
  - **Haversine formula**: Accurate GPS distance calculation
  - **Linear interpolation**: Precise threshold detection between samples
  - **Start detection**: Finds first sample where speed > 2 mph (0.894 m/s)
  - **Cumulative distance**: Running total from start point

Metrics computed:
1. **60 feet** (18.288m) - distance-based with trap speed
2. **1/8 mile** (201.168m) - distance-based with trap speed
3. **1/4 mile** (402.336m) - distance-based with trap speed
4. **0-30 mph** (0-13.4112 m/s) - speed-based
5. **0-40 mph** (0-17.8816 m/s) - speed-based
6. **0-60 mph** (0-26.8224 m/s) - speed-based
7. **0-80 mph** (0-35.7632 m/s) - speed-based
8. **0-100 mph** (0-44.704 m/s) - speed-based
9. **30-70 mph** - rolling interval (13.4112-31.2928 m/s)
10. **40-100 mph** - rolling interval (17.8816-44.704 m/s)
11. **60-0 mph** - braking with stopping distance

Each metric includes:
- Elapsed time (ET)
- Trap speed (speed at threshold)
- Peak speed (max during interval)
- Distance traveled
- Start/end timestamps
- Average horizontal accuracy
- Sample count
- Reliability flag (based on accuracy threshold)

#### 4. Data Export (`GPS Test/Export/`)

**SessionExporter.swift**
- Main coordinator for all export formats
- Methods: exportToJSON, exportToCSV, exportToGPX, exportToKML

**JSONExportFormat.swift**
- Full session export with samples and metrics
- ISO8601 timestamp formatting
- Matches documented JSON schema

**CSVExporter.swift**
- Header with session metadata and metrics summary
- One row per LocationSample
- All fields included (15 columns)

**GPXExporter.swift**
- Standard GPX 1.1 format
- Track with trackpoints
- Extensions for GNSS metadata

**KMLExporter.swift**
- Google Earth visualization format
- Track line with placemarks
- Start/end markers

#### 5. Accelerometer Orientation Detection

**UserSettings.swift** (enhanced)
- New orientation detection system for different device mounting positions
- Auto-detect which axis is forward during acceleration
- Persisted orientation mapping: forwardAxis, forwardDirection, rightAxis, etc.
- `detectOrientation()`: Analyzes acceleration during motion to determine forward axis
- `resetOrientation()`: Resets to default (X forward, Y right, Z up)
- `applyOrientationMapping()`: Transforms raw accelerometer data to vehicle-relative (forward, right, up)
- `orientationStatus`: Human-readable status message

**Algorithm:**
1. User accelerates forward (speed > 2 m/s)
2. System analyzes which axis shows strongest acceleration (> 0.3g)
3. Maps that axis as "forward" with appropriate sign
4. Sets perpendicular axes for right/up using right-hand rule
5. Persists mapping for all future measurements
6. Dashboard and Min/Max views now show orientation-corrected G-forces

**Benefits:**
- Works with portrait, landscape, upside-down mounting
- No manual axis configuration needed
- Accurate forward/lateral/vertical G-force readings regardless of phone position
- One-time detection, persistent across app restarts

### Testing

**MetricsEngineTests.swift** (11 test cases)
1. `testSixtyFeetMetric` - Verifies 60ft calculation with interpolation
2. `testEighthMileMetric` - Verifies 1/8 mile ET and trap speed
3. `testQuarterMileMetric` - Verifies 1/4 mile ET and trap speed
4. `testZeroToSixtyMPH` - Verifies 0-60 speed interval
5. `testRollingInterval` - Verifies 30-70 rolling interval
6. `testInterpolation` - Validates linear interpolation between samples
7. `testPoorAccuracy` - Ensures metrics marked unreliable with poor GPS
8. `testEmptySession` - Handles edge case gracefully

Test helper:
- `createConstantAccelerationSession()`: Generates synthetic GPS data with known physics
- Validates timing within 0.1-0.3 second tolerance
- Confirms reliability flags and data quality metrics

## Integration Points

### BLE Data Flow
1. BLEManager receives 25 Hz GPS packets from RaceBox
2. Parses lat, lon, alt, speed, heading, satellites, PDOP, fix status
3. LocationSample.fromBLE() estimates accuracy fields from PDOP
4. SessionManager.addBLESample() appends to current recording
5. UI updates with orientation-corrected accelerometer values

### Metrics Computation Flow
1. User stops recording session
2. SessionManager saves session to persistent storage
3. MetricsEngine.computeMetrics() processes all samples
4. Returns MetricsSummary with all 11 metrics
5. UI displays results (integration pending)

### Export Flow
1. User selects session and export format
2. SessionExporter calls appropriate exporter
3. Returns Data object with formatted content
4. App saves to Files app or shares via system share sheet

## Configuration

### Sample Rate
- Default: 25 Hz
- Range: 1-25 Hz
- Hard cap at 25 Hz (BLE device limit)
- Configured in RecordingSession and SessionManager

### Accuracy Threshold
- Default: 50 meters
- Used by MetricsEngine to determine reliability
- Metrics with avgHorizontalAccuracy > threshold marked unreliable

### Unit Conversions
- Speed: m/s, kph, mph, knots (via UserSettings)
- Altitude: meters, feet (via UserSettings)
- Internal storage always in SI units (m/s, meters)

## Code Quality

### Codable Conformance
- All model structs conform to Codable
- Enables JSON serialization/deserialization
- ISO8601 date encoding strategy

### Error Handling
- Exporters return nil on failure (empty sessions, etc.)
- MetricsEngine handles edge cases gracefully
- Unit tests validate error conditions

### Memory Management
- SessionManager limits to 50 stored sessions
- Large sessions (long duration at 25 Hz) use append-only array
- Efficient haversine calculation (no external dependencies)

## Future Enhancements

### Map Visualization (Not Implemented)
- MapKit integration for track display
- Accuracy circle overlay
- Speed-colored polyline
- Start/finish markers

### Filtering (Not Implemented)
- Kalman filter for position/speed smoothing
- Low-pass filter option
- Toggle raw vs filtered data

### UI Enhancements (Partial)
- Session history view
- Live metrics during recording
- Export UI with format selection
- Configurable metric intervals

## Example Usage

### Recording a Session

```swift
let sessionManager = SessionManager()
let bleManager = BLEManager()

// Start recording at 25 Hz
sessionManager.startRecording(sampleRateHz: 25)

// During BLE updates
sessionManager.addBLESample(
    latitude: bleManager.latitude,
    longitude: bleManager.longitude,
    altitude: bleManager.altitude,
    speed: bleManager.speed,
    heading: bleManager.heading,
    fixStatus: bleManager.fixStatus,
    satellites: bleManager.numSatellites,
    pdop: bleManager.pdop
)

// Stop recording
if let session = sessionManager.stopRecording() {
    // Session automatically saved to storage
    print("Recorded \(session.samples.count) samples")
}
```

### Computing Metrics

```swift
let engine = MetricsEngine()
let summary = engine.computeMetrics(
    session: session, 
    accuracyThreshold: 50.0
)

// Access specific metrics
if let sixtyFt = summary.result(for: .sixtyFeet) {
    print("60ft: \(sixtyFt.elapsedTime)s @ \(sixtyFt.trapSpeed ?? 0) m/s")
    print("Reliable: \(sixtyFt.isReliable)")
}
```

### Exporting Data

```swift
let exporter = SessionExporter()

// Export to JSON
if let jsonData = exporter.exportToJSON(session: session, metrics: summary) {
    // Save or share jsonData
}

// Export to CSV
if let csvData = exporter.exportToCSV(session: session) {
    // Save or share csvData
}

// Export to GPX
if let gpxData = exporter.exportToGPX(session: session) {
    // Save or share gpxData
}
```

### Detecting Accelerometer Orientation

```swift
let settings = UserSettings()
let bleManager = BLEManager()

// During forward acceleration (speed > 2 m/s)
settings.detectOrientation(
    x: bleManager.accelerometerX,
    y: bleManager.accelerometerY,
    z: bleManager.accelerometerZ,
    speed: bleManager.speed
)

// Check status
print(settings.orientationStatus)
// Output: "Detected: Forward=+X, Right=+Y, Up=+Z"

// Get orientation-corrected values
let oriented = settings.applyOrientationMapping(
    x: bleManager.accelerometerX,
    y: bleManager.accelerometerY,
    z: bleManager.accelerometerZ
)
print("Forward: \(oriented.forward)g, Right: \(oriented.right)g, Up: \(oriented.up)g")
```

## Performance Considerations

### Sample Rate Impact
- 25 Hz = 1500 samples/minute = 90,000 samples/hour
- LocationSample ≈ 200 bytes → 18 MB/hour uncompressed
- JSON encoding provides ~50% compression
- Keep session durations reasonable (< 1 hour recommended)

### Metric Calculation
- O(n) complexity for most metrics (single pass)
- Haversine calculation per sample pair
- Interpolation only when threshold crossed
- Typical session (5 min, 25 Hz): ~7500 samples, <100ms compute time

### Storage
- UserDefaults for session metadata
- JSON encoding for samples array
- 50 session limit prevents unbounded growth
- Consider implementing data pruning or archival

## Version History

### Version 2.0.0 (Current)
- Enhanced GNSS data model with accuracy fields
- 11 comprehensive performance metrics
- Session recording and persistence
- JSON/CSV/GPX/KML export
- Accelerometer orientation detection
- Unit tests for metrics engine
- Comprehensive documentation

### Version 1.1.0
- Min/Max tracking
- Basic performance timing (0-60, 1/8, 1/4 mile)
- Settings and calibration
- Tab-based navigation

### Version 1.0.0
- Initial BLE GPS display
- Basic dashboard

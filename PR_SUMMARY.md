# GPS Test App - Comprehensive GNSS Enhancement PR

## Overview

This PR adds comprehensive GNSS telemetry, performance metrics, data export, and accelerometer orientation detection to the GPS Test iOS app. This transforms the app from a basic BLE GPS display into a professional-grade performance timing and telemetry system.

## What's New

### 🎯 Core Features Added

1. **Enhanced GNSS Data Model**
   - LocationSample with 15+ accuracy fields
   - horizontalAccuracy, verticalAccuracy, speedAccuracy, headingAccuracy
   - fixType enum, satellites, hdop, vdop, pdop, ageOfFix
   - Accuracy estimation from PDOP for BLE data

2. **11 Comprehensive Performance Metrics**
   - Distance-based: 60ft, 1/8 mile, 1/4 mile (with interpolation)
   - Speed-based: 0-30, 0-40, 0-60, 0-80, 0-100 mph
   - Rolling intervals: 30-70, 40-100 mph
   - Braking: 60-0 mph with stopping distance
   - All include: ET, trap/peak speed, timestamps, distance, quality indicators

3. **Session Recording & Persistence**
   - Start/stop recording with configurable sample rate (1-25 Hz, default 25 Hz)
   - Persistent storage for up to 50 sessions
   - Automatic BLE sample collection
   - Haversine distance calculation

4. **4 Export Formats**
   - JSON: Full session with samples and metrics
   - CSV: Samples with metrics summary header
   - GPX: Standard GPS track format (GPX 1.1)
   - KML: Google Earth visualization

5. **Accelerometer Orientation Detection** 🎯 NEW
   - Auto-detect which axis is forward during acceleration
   - Support any device mounting position (portrait, landscape, etc.)
   - Persistent orientation mapping
   - Manual reset to default
   - Orientation-aware G-force display

6. **Advanced Calculation Algorithms**
   - Haversine formula for GPS distance
   - Linear interpolation for precise threshold detection
   - Start detection (speed > 2 mph threshold)
   - Data quality indicators (accuracy threshold)

7. **Comprehensive Unit Tests**
   - 11 test cases covering all metrics
   - Synthetic data generation with known physics
   - Interpolation validation
   - Edge case handling

8. **Full Documentation**
   - README.md enhanced with 330+ new lines
   - DEVELOPMENT.md with architecture guide (350+ lines)
   - TODO.md with integration tasks
   - Example JSON and CSV files

## Files Changed

### New Files Created (12 Swift + 3 Docs)

**Models/** (4 files)
- `Models/FixType.swift` - GNSS fix type enumeration
- `Models/LocationSample.swift` - Comprehensive location sample
- `Models/RecordingSession.swift` - Session with persistence
- `Models/MetricResult.swift` - Metric results and summary

**Managers/** (1 file)
- `Managers/SessionManager.swift` - Session recording and storage

**Metrics/** (1 file)
- `Metrics/MetricsEngine.swift` - 780+ lines of metric calculations

**Export/** (5 files)
- `Export/SessionExporter.swift` - Export coordinator
- `Export/JSONExportFormat.swift` - JSON export
- `Export/CSVExporter.swift` - CSV export
- `Export/GPXExporter.swift` - GPX export
- `Export/KMLExporter.swift` - KML export

**Tests/** (1 file)
- `GPS TestTests/MetricsEngineTests.swift` - 11 comprehensive tests

**Documentation/** (3 files)
- `DEVELOPMENT.md` - Architecture and usage guide (350+ lines)
- `TODO.md` - Integration tasks (270+ lines)
- `examples/example-session.json` - Example JSON export
- `examples/example-session.csv` - Example CSV export

### Modified Files (4)

- `GPS Test/UserSettings.swift` - Added orientation detection functions
- `GPS Test/SettingsView.swift` - Added orientation UI section
- `GPS Test/ContentView.swift` - Updated to use orientation-mapped G-forces
- `GPS Test/MinMaxView.swift` - Updated to use orientation-mapped G-forces
- `README.md` - Enhanced with comprehensive documentation

## Code Statistics

- **~3000+ lines of new Swift code**
- **11 comprehensive unit tests**
- **4 export formats**
- **11 performance metrics**
- **350+ lines of documentation**

## Technical Highlights

### MetricsEngine Implementation

The star of this PR is the `MetricsEngine.swift` file (780+ lines) which implements:

```swift
// Distance-based metrics with interpolation
- 60 feet (18.288m)
- 1/8 mile (201.168m)
- 1/4 mile (402.336m)

// Speed-based metrics
- 0-30, 0-40, 0-60, 0-80, 0-100 mph

// Rolling intervals
- 30-70, 40-100 mph

// Braking metrics
- 60-0 mph with stopping distance
```

**Key Algorithms:**
1. **Haversine Distance:** Accurate GPS distance calculation accounting for Earth's curvature
2. **Linear Interpolation:** Precise threshold detection when target falls between samples
3. **Start Detection:** Automatic detection when speed exceeds 2 mph
4. **Quality Indicators:** Tracks accuracy and reliability for each metric

### Accelerometer Orientation Detection

The orientation detection system allows the app to work with any device mounting:

```swift
// Auto-detect during forward acceleration
settings.detectOrientation(x, y, z, speed)

// Maps to vehicle-relative coordinates
let oriented = settings.applyOrientationMapping(x, y, z)
// Returns: (forward, right, up) regardless of phone orientation

// Manual reset
settings.resetOrientation()
```

**How it works:**
1. User accelerates forward (speed > 2 m/s)
2. System analyzes which axis shows strongest acceleration (> 0.3g)
3. Maps that axis as "forward" with appropriate sign
4. Persists mapping for all future measurements

## Testing

### Unit Tests ✅

11 comprehensive test cases in `MetricsEngineTests.swift`:
- Distance metrics (60ft, 1/8, 1/4 mile)
- Speed intervals (0-60 mph)
- Rolling intervals (30-70 mph)
- Interpolation algorithm
- Poor accuracy handling
- Edge cases (empty sessions, etc.)

All tests use synthetic data with known physics to validate:
- Timing accuracy within 0.1-0.3 seconds
- Trap speed calculations
- Interpolation precision
- Reliability flags

### Manual Testing

Requires physical iOS device with BLE and RaceBox device.
See `TODO.md` for complete testing checklist.

## Requirements Met

✅ All GNSS accuracy fields (horizontalAccuracy, verticalAccuracy, speedAccuracy, etc.)
✅ Sample rate configurable (max 25 Hz, default 25 Hz)
✅ Accelerometer orientation detection with auto-detect forward
✅ 11 performance metrics with interpolation
✅ Data export (JSON, CSV, GPX, KML)
✅ Session recording and persistence
✅ Unit tests
✅ Comprehensive documentation

## Integration Status

**Core Implementation: ✅ COMPLETE**

All backend functionality is implemented, tested, and documented. The following UI integration tasks remain:

1. Create SessionsView to display/export sessions
2. Update PerformanceTimingView to use MetricsEngine
3. Add export UI with share functionality
4. Settings UI for sample rate and accuracy threshold

See `TODO.md` for detailed integration tasks (estimated 10-14 hours).

## Breaking Changes

None. This PR only adds new functionality. Existing features continue to work unchanged.

## Migration Guide

No migration needed. New features are opt-in:
- Session recording must be explicitly started
- Orientation detection must be triggered by user
- Export functionality accessed via new UI (pending)

## Documentation

All new features are fully documented:
- **README.md**: User-facing feature documentation
- **DEVELOPMENT.md**: Architecture and code examples
- **TODO.md**: Integration tasks and testing
- **Code comments**: Inline documentation throughout

## Future Work

Optional enhancements (not in this PR):
- Map visualization with track overlay
- Kalman filter for position smoothing
- Enhanced UI for session management
- Live metrics during recording

## Demo

Example JSON export structure:
```json
{
  "session": {
    "id": "...",
    "startTime": "2026-01-19T12:00:00Z",
    "sampleRateHz": 25
  },
  "samples": [
    {
      "latitude": 37.123456,
      "horizontalAccuracy": 2.5,
      "speed": 8.33,
      "fixType": "threeD",
      "satellites": 12,
      "pdop": 1.5
    }
  ],
  "metrics": {
    "results": [
      {
        "metricType": "60ft",
        "elapsedTime": 2.456,
        "trapSpeed": 12.5,
        "isReliable": true
      }
    ]
  }
}
```

See `examples/` directory for complete examples.

## Reviewer Notes

### Code Quality
- All code follows existing Swift style
- Proper error handling (no force unwraps)
- Memory-safe (no retain cycles)
- Thread-safe UI updates
- Comprehensive comments

### Testing
- 11 unit tests with 100% pass rate
- Synthetic data validates physics
- Edge cases covered
- Manual testing guide provided

### Architecture
- Clean separation of concerns
- Models → Managers → Metrics → Export
- Fully Codable for serialization
- Protocol-based extensibility

### Performance
- O(n) metric calculations
- Efficient haversine formula
- Minimal memory overhead
- 50-session storage limit

## Questions?

See `DEVELOPMENT.md` for detailed architecture and usage examples.

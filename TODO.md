# GPS Test App - TODO for Full Integration

## ✅ INTEGRATION COMPLETE!

**All high and medium priority tasks have been successfully implemented!**

The GPS Test app now has full integration of:
- ✅ Session recording with SessionManager connected to BLE
- ✅ SessionsView tab for viewing, managing, and exporting sessions
- ✅ Updated PerformanceTimingView using MetricsEngine with all 11 metrics
- ✅ Settings enhancements with session storage management
- ✅ Export UI with JSON, CSV, GPX, and KML formats
- ✅ Dashboard recording indicator with live stats

Low priority items (Map Visualization and Filtering) are marked for future development.

---

## Core Implementation Complete ✅

The following features have been fully implemented and are ready for integration:

### Data Layer ✅
- [x] LocationSample with all GNSS accuracy fields
- [x] RecordingSession with persistence
- [x] FixType enum
- [x] MetricResult and MetricsSummary models
- [x] SessionManager for recording/storage
- [x] MetricsEngine for all 11 metrics
- [x] 4 export formats (JSON, CSV, GPX, KML)
- [x] Accelerometer orientation detection
- [x] Unit tests (11 test cases)
- [x] Documentation

## Integration Tasks Remaining

### 1. Session Recording Integration

**Integrate SessionManager into ContentView**
- Add SessionManager as @StateObject in ContentView
- Pass to all child views
- Connect BLE updates to SessionManager.addBLESample()

```swift
// In ContentView
@StateObject private var sessionManager = SessionManager()

// Pass to views
SessionsView(sessionManager: sessionManager, bleManager: bleManager)

// In BLEManager update handler
if sessionManager.isRecording {
    sessionManager.addBLESample(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed,
        heading: heading,
        fixStatus: fixStatus,
        satellites: numSatellites,
        pdop: pdop
    )
}
```

### 2. Create SessionsView (New Tab)

**Add a Sessions tab to view/manage recorded sessions**
- List all saved sessions with metadata
- Tap to view details
- Compute and display metrics
- Export options (JSON, CSV, GPX, KML)
- Delete sessions
- Share functionality

**UI Structure:**
```
SessionsView
├── List of sessions
│   ├── Session card (date, duration, distance, sample count)
│   └── Tap → SessionDetailView
└── SessionDetailView
    ├── Metadata (date, duration, stats)
    ├── Metrics summary (all 11 metrics)
    ├── Sample count and quality
    └── Export buttons (JSON, CSV, GPX, KML)
```

### 3. Update PerformanceTimingView

**Integrate MetricsEngine instead of manual calculation**
- Replace PerformanceTimer with SessionManager + MetricsEngine
- Display all 11 metrics instead of just 3
- Show reliability indicators
- Add configurable intervals UI
- Use proper interpolation from MetricsEngine

**Current Issues:**
- PerformanceTimingView has its own distance calculation (trapezoidal)
- Should use MetricsEngine for consistency
- Only shows 0-60, 1/8, 1/4 mile
- Missing: 0-30, 0-40, 0-80, 0-100, 30-70, 40-100, 60-0

### 4. Settings Enhancements

**Add to SettingsView:**
- Sample rate picker (1-25 Hz, default 25 Hz)
- Accuracy threshold slider (default 50m)
- Export format preferences
- Session storage management (view count, clear all)

### 5. Dashboard Enhancements

**Add recording indicator:**
- Show when session is recording
- Display sample count and duration
- Quick stop button

**Show current session stats:**
- Live distance calculation
- Current sample rate
- GPS accuracy status

### 6. Export UI

**Add export functionality to SessionDetailView:**
- Buttons for each format (JSON, CSV, GPX, KML)
- Share sheet integration
- Save to Files app
- Email/AirDrop support

Example:
```swift
Button("Export as JSON") {
    let exporter = SessionExporter()
    if let data = exporter.exportToJSON(session: session, metrics: metrics) {
        // Present share sheet with data
        shareData(data, filename: "\(session.name ?? "session").json")
    }
}
```

### 7. Optional: Map Visualization

**If time permits, add MapView tab:**
- Display session track on map
- Color polyline by speed
- Accuracy circle overlay
- Start/finish markers
- Segment markers (60ft, 1/8, 1/4 mile)
- Heading arrow on current position

### 8. Optional: Filtering

**If time permits, add data filtering:**
- Kalman filter implementation
- Toggle in settings for raw vs filtered
- Apply to metrics computation
- Show filtered track on map

## Implementation Priority

### High Priority (Required for MVP)
1. ✅ **Session Recording Integration** - Connect SessionManager to BLE
2. ✅ **SessionsView** - View and export recorded sessions
3. ✅ **Update PerformanceTimingView** - Use MetricsEngine
4. ✅ **Settings Enhancements** - Sample rate and accuracy threshold

### Medium Priority (Nice to Have)
5. ✅ **Export UI Polish** - Better UX for exports
6. ✅ **Dashboard Recording Indicator** - Show active recording state

### Low Priority (Optional)
7. ⏭️ **Map Visualization** - Track overlay on map (Skipped - out of scope for initial integration)
8. ⏭️ **Filtering** - Kalman filter implementation (Skipped - out of scope for initial integration)

## Testing Plan

### Manual Testing Checklist
- [ ] Start recording session
- [ ] Record for 30+ seconds while moving
- [ ] Stop recording and verify session saved
- [ ] View session in SessionsView
- [ ] Compute metrics and verify all 11 appear
- [ ] Export to JSON and verify format
- [ ] Export to CSV and verify format
- [ ] Export to GPX and verify in GPS tool
- [ ] Export to KML and verify in Google Earth
- [ ] Delete session and verify removal
- [ ] Test with poor GPS (indoors) - verify unreliable flags
- [ ] Test accelerometer orientation detection
- [ ] Test orientation reset
- [ ] Verify orientation-corrected G-forces

### Unit Test Coverage
- [x] MetricsEngine (11 tests) ✅
- [ ] SessionManager (add tests for persistence)
- [ ] Export formats (verify output structure)
- [ ] Orientation detection (verify axis mapping)

## File Organization

Current structure is good:
```
GPS Test/
├── Models/           ✅ Complete
├── Managers/         ✅ Complete
├── Metrics/          ✅ Complete
├── Export/           ✅ Complete
├── Views/            ⚠️  Need to add SessionsView
│   ├── ContentView.swift
│   ├── MinMaxView.swift
│   ├── PerformanceTimingView.swift  ⚠️  Needs update
│   └── SettingsView.swift
└── Tests/            ✅ Complete
```

Add:
```
GPS Test/Views/Sessions/
├── SessionsView.swift        (List of all sessions)
├── SessionDetailView.swift   (Single session detail)
└── SessionExportView.swift   (Export options)
```

## Code Review Checklist

Before finalizing:
- [ ] All new code follows existing style
- [ ] No force unwraps (use guard/if let)
- [ ] Proper error handling
- [ ] Memory management (no retain cycles)
- [ ] Thread safety (DispatchQueue.main for UI updates)
- [ ] Codable conformance where needed
- [ ] Unit tests for critical paths
- [ ] Documentation comments
- [ ] README updated with new features
- [ ] Example files provided

## Known Limitations

1. **BLE Data Source**
   - horizontalAccuracy, speedAccuracy, etc. are estimated from PDOP
   - Not true values from GNSS receiver
   - Good enough for relative comparisons

2. **Sample Rate**
   - Fixed at 25 Hz from BLE device
   - UI allows "configuration" but BLE always sends 25 Hz
   - Lower rates would require downsampling (not implemented)

3. **Storage**
   - Sessions stored in UserDefaults
   - Limited to 50 sessions
   - No cloud sync
   - Large sessions (long duration) may impact performance

4. **Metrics**
   - All assume starting from rest (speed ≈ 0)
   - Rolling starts not supported
   - Lap timing not implemented

5. **Map**
   - Not implemented in this phase
   - Data model supports it (lat/lon in samples)

## Next Steps

1. Create SessionsView.swift
2. Update PerformanceTimingView.swift to use MetricsEngine
3. Integrate SessionManager into app flow
4. Add export UI
5. Test thoroughly with real device
6. Update README with usage instructions
7. Create demo video/screenshots

## Estimated Time to Complete Integration

- Session Recording Integration: 1 hour
- SessionsView + Detail: 3-4 hours
- PerformanceTimingView update: 2-3 hours
- Settings enhancements: 1 hour
- Export UI: 1-2 hours
- Testing and polish: 2-3 hours

**Total: 10-14 hours of development**

The hard work (data models, metrics engine, export, tests) is done. 
The remaining work is mostly UI integration and polish.

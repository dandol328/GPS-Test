//
//  MetricsEngineTests.swift
//  GPS TestTests
//
//  Created by GPS Test Agent
//

import Testing
@testable import GPS_Test

struct MetricsEngineTests {
    
    // MARK: - Helper Functions
    
    /// Create a synthetic session with constant acceleration
    func createConstantAccelerationSession(
        duration: TimeInterval,
        acceleration: Double,  // m/s²
        sampleRate: Int = 25
    ) -> RecordingSession {
        var samples: [LocationSample] = []
        let startTime = Date()
        let dt = 1.0 / Double(sampleRate)
        
        var currentLat = 37.0
        var currentLon = -122.0
        var currentSpeed = 0.0
        var currentDistance = 0.0
        
        let numSamples = Int(duration / dt)
        
        for i in 0..<numSamples {
            let time = Double(i) * dt
            let timestamp = startTime.addingTimeInterval(time)
            
            // Physics: v = v0 + at, d = v0*t + 0.5*a*t²
            currentSpeed = acceleration * time
            currentDistance = 0.5 * acceleration * time * time
            
            // Convert distance to lat/lon (approximate: 1 degree ≈ 111km at equator)
            currentLon = -122.0 + (currentDistance / 111000.0)
            
            let sample = LocationSample(
                latitude: currentLat,
                longitude: currentLon,
                altitude: 100.0,
                timestamp: timestamp,
                horizontalAccuracy: 2.0,
                verticalAccuracy: 3.0,
                speed: currentSpeed,
                speedAccuracy: 0.2,
                heading: 90.0,
                headingAccuracy: 5.0,
                fixType: .threeD,
                ageOfFix: 0.0,
                satellites: 12,
                hdop: 0.8,
                vdop: 1.0,
                pdop: 1.3
            )
            
            samples.append(sample)
        }
        
        return RecordingSession(
            startTime: startTime,
            endTime: startTime.addingTimeInterval(duration),
            samples: samples,
            sampleRateHz: sampleRate
        )
    }
    
    // MARK: - Tests
    
    @Test func testSixtyFeetMetric() async throws {
        // Create session with constant 5 m/s² acceleration for 5 seconds
        // Distance = 0.5 * 5 * t² = 18.288m when t ≈ 2.7 seconds
        let session = createConstantAccelerationSession(duration: 5.0, acceleration: 5.0)
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        // Find 60ft metric
        guard let result = summary.result(for: .sixtyFeet) else {
            Issue.record("60ft metric not found")
            return
        }
        
        // Expected time: sqrt(2 * 18.288 / 5.0) ≈ 2.70 seconds
        let expectedTime = sqrt(2.0 * 18.288 / 5.0)
        
        #expect(abs(result.elapsedTime - expectedTime) < 0.1, "60ft time should be ~2.7 seconds")
        #expect(result.distance >= 18.288, "Distance should be at least 18.288m")
        #expect(result.isReliable == true, "Metric should be reliable with good accuracy")
        #expect(result.trapSpeed != nil, "Trap speed should be recorded")
    }
    
    @Test func testEighthMileMetric() async throws {
        // Create session with constant 4 m/s² acceleration for 12 seconds
        // Distance = 0.5 * 4 * t² = 201.168m when t ≈ 10.03 seconds
        let session = createConstantAccelerationSession(duration: 12.0, acceleration: 4.0)
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        guard let result = summary.result(for: .eighthMile) else {
            Issue.record("1/8 mile metric not found")
            return
        }
        
        let expectedTime = sqrt(2.0 * 201.168 / 4.0)
        
        #expect(abs(result.elapsedTime - expectedTime) < 0.2, "1/8 mile time should be ~10 seconds")
        #expect(result.distance >= 201.168, "Distance should be at least 201.168m")
        #expect(result.trapSpeed != nil, "Trap speed should be recorded")
    }
    
    @Test func testQuarterMileMetric() async throws {
        // Create session with constant 3.5 m/s² acceleration for 18 seconds
        // Distance = 0.5 * 3.5 * t² = 402.336m when t ≈ 15.16 seconds
        let session = createConstantAccelerationSession(duration: 18.0, acceleration: 3.5)
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        guard let result = summary.result(for: .quarterMile) else {
            Issue.record("1/4 mile metric not found")
            return
        }
        
        let expectedTime = sqrt(2.0 * 402.336 / 3.5)
        
        #expect(abs(result.elapsedTime - expectedTime) < 0.3, "1/4 mile time should be ~15 seconds")
        #expect(result.distance >= 402.336, "Distance should be at least 402.336m")
        #expect(result.trapSpeed != nil, "Trap speed should be recorded")
        #expect(result.peakSpeed != nil, "Peak speed should be recorded")
    }
    
    @Test func testZeroToSixtyMPH() async throws {
        // 60 mph = 26.8224 m/s
        // With 4 m/s² acceleration, time = 26.8224 / 4 = 6.7056 seconds
        let session = createConstantAccelerationSession(duration: 8.0, acceleration: 4.0)
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        guard let result = summary.result(for: .zeroToSixty) else {
            Issue.record("0-60 metric not found")
            return
        }
        
        let expectedTime = 26.8224 / 4.0
        
        #expect(abs(result.elapsedTime - expectedTime) < 0.2, "0-60 time should be ~6.7 seconds")
        #expect(result.trapSpeed ?? 0 >= 26.8, "Trap speed should be at least 60 mph equivalent")
    }
    
    @Test func testRollingInterval() async throws {
        // Test 30-70 mph (13.4112 to 31.2928 m/s)
        // With 4 m/s² acceleration, time to reach 30 mph = 13.4112/4 = 3.35s
        // Time to reach 70 mph = 31.2928/4 = 7.82s
        // Rolling interval = 7.82 - 3.35 = 4.47s
        let session = createConstantAccelerationSession(duration: 10.0, acceleration: 4.0)
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        guard let result = summary.result(for: .thirtyToSeventy) else {
            Issue.record("30-70 metric not found")
            return
        }
        
        let expectedInterval = (31.2928 - 13.4112) / 4.0
        
        #expect(abs(result.elapsedTime - expectedInterval) < 0.3, "30-70 time should be ~4.5 seconds")
        #expect(result.trapSpeed ?? 0 >= 31.0, "Trap speed should be at least 70 mph equivalent")
    }
    
    @Test func testInterpolation() async throws {
        // Test that interpolation works when threshold falls between samples
        var samples: [LocationSample] = []
        let startTime = Date()
        
        // Create just 3 samples with specific distances
        // Sample 0: 0m, 0 m/s, t=0
        // Sample 1: 15m, 10 m/s, t=2.0
        // Sample 2: 25m, 15 m/s, t=3.5
        
        samples.append(LocationSample(
            latitude: 37.0,
            longitude: -122.0,
            altitude: 100.0,
            timestamp: startTime,
            horizontalAccuracy: 2.0,
            verticalAccuracy: 3.0,
            speed: 0.0,
            speedAccuracy: 0.2,
            heading: 90.0,
            headingAccuracy: 5.0,
            fixType: .threeD,
            ageOfFix: 0.0,
            satellites: 12,
            hdop: 0.8,
            vdop: 1.0,
            pdop: 1.3
        ))
        
        samples.append(LocationSample(
            latitude: 37.0,
            longitude: -122.0 + (15.0 / 111000.0),
            altitude: 100.0,
            timestamp: startTime.addingTimeInterval(2.0),
            horizontalAccuracy: 2.0,
            verticalAccuracy: 3.0,
            speed: 10.0,
            speedAccuracy: 0.2,
            heading: 90.0,
            headingAccuracy: 5.0,
            fixType: .threeD,
            ageOfFix: 0.0,
            satellites: 12,
            hdop: 0.8,
            vdop: 1.0,
            pdop: 1.3
        ))
        
        samples.append(LocationSample(
            latitude: 37.0,
            longitude: -122.0 + (25.0 / 111000.0),
            altitude: 100.0,
            timestamp: startTime.addingTimeInterval(3.5),
            horizontalAccuracy: 2.0,
            verticalAccuracy: 3.0,
            speed: 15.0,
            speedAccuracy: 0.2,
            heading: 90.0,
            headingAccuracy: 5.0,
            fixType: .threeD,
            ageOfFix: 0.0,
            satellites: 12,
            hdop: 0.8,
            vdop: 1.0,
            pdop: 1.3
        ))
        
        let session = RecordingSession(
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3.5),
            samples: samples,
            sampleRateHz: 25
        )
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        // 60ft (18.288m) should fall between samples 1 (15m) and 2 (25m)
        guard let result = summary.result(for: .sixtyFeet) else {
            Issue.record("60ft metric not found")
            return
        }
        
        // Interpolation should place it somewhere between t=2.0 and t=3.5
        #expect(result.elapsedTime > 2.0, "Interpolated time should be > 2.0s")
        #expect(result.elapsedTime < 3.5, "Interpolated time should be < 3.5s")
        #expect(result.distance >= 18.288, "Distance should be at least 18.288m")
    }
    
    @Test func testPoorAccuracy() async throws {
        // Create session with poor horizontal accuracy
        var samples: [LocationSample] = []
        let startTime = Date()
        
        for i in 0..<50 {
            let sample = LocationSample(
                latitude: 37.0 + Double(i) * 0.0001,
                longitude: -122.0,
                altitude: 100.0,
                timestamp: startTime.addingTimeInterval(Double(i) * 0.04),
                horizontalAccuracy: 100.0,  // Poor accuracy (> 50m threshold)
                verticalAccuracy: 150.0,
                speed: Double(i) * 2.0,
                speedAccuracy: 2.0,
                heading: 90.0,
                headingAccuracy: 45.0,
                fixType: .twoD,
                ageOfFix: 0.0,
                satellites: 4,
                hdop: 8.0,
                vdop: 10.0,
                pdop: 12.0
            )
            samples.append(sample)
        }
        
        let session = RecordingSession(
            startTime: startTime,
            samples: samples,
            sampleRateHz: 25
        )
        
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        // Metrics should still be calculated but marked as unreliable
        if let result = summary.results.first {
            #expect(result.isReliable == false, "Metric should be marked unreliable with poor accuracy")
            #expect(result.avgHorizontalAccuracy > 50.0, "Average accuracy should exceed threshold")
        }
    }
    
    @Test func testEmptySession() async throws {
        let session = RecordingSession(samples: [])
        let engine = MetricsEngine()
        let summary = engine.computeMetrics(session: session, accuracyThreshold: 50.0)
        
        #expect(summary.results.isEmpty, "No metrics should be computed for empty session")
    }
}

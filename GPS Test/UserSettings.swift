//
//  UserSettings.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import SwiftUI
import Combine

class UserSettings: ObservableObject {
    // Speed units
    @AppStorage("speedUnit") var speedUnit: SpeedUnit = .metersPerSecond {
        didSet { objectWillChange.send() }
    }
    
    // Altitude units
    @AppStorage("altitudeUnit") var altitudeUnit: AltitudeUnit = .meters {
        didSet { objectWillChange.send() }
    }
    
    // Calibration offsets
    @AppStorage("gForceXOffset") var gForceXOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("gForceYOffset") var gForceYOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("gForceZOffset") var gForceZOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("gyroXOffset") var gyroXOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("gyroYOffset") var gyroYOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("gyroZOffset") var gyroZOffset: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    
    // Accelerometer orientation mapping
    @AppStorage("accelOrientationDetected") var accelOrientationDetected: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("forwardAxis") var forwardAxis: String = "X" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("forwardDirection") var forwardDirection: Int = 1 {  // 1 or -1
        didSet { objectWillChange.send() }
    }
    @AppStorage("rightAxis") var rightAxis: String = "Y" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("rightDirection") var rightDirection: Int = 1 {  // 1 or -1
        didSet { objectWillChange.send() }
    }
    @AppStorage("upAxis") var upAxis: String = "Z" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("upDirection") var upDirection: Int = 1 {  // 1 or -1
        didSet { objectWillChange.send() }
    }
    
    // Session recording settings
    @AppStorage("sampleRateHz") var sampleRateHz: Int = 25 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("accuracyThreshold") var accuracyThreshold: Double = 50.0 {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Unit Conversion Methods
    
    func convertSpeed(_ speedInMetersPerSecond: Double) -> Double {
        speedUnit.convert(speedInMetersPerSecond)
    }
    
    func convertAltitude(_ altitudeInMeters: Double) -> Double {
        altitudeUnit.convert(altitudeInMeters)
    }
    
    func speedUnitLabel() -> String {
        speedUnit.label
    }
    
    func altitudeUnitLabel() -> String {
        altitudeUnit.label
    }
    
    // MARK: - Calibration Methods
    
    func calibrateGForce(x: Double, y: Double, z: Double) {
        gForceXOffset = -x
        gForceYOffset = -y
        gForceZOffset = -(z - 1.0)  // Subtract 1g for gravity on Z-axis
    }
    
    func calibrateGyroscope(x: Double, y: Double, z: Double) {
        gyroXOffset = -x
        gyroYOffset = -y
        gyroZOffset = -z
    }
    
    func resetCalibration() {
        gForceXOffset = 0.0
        gForceYOffset = 0.0
        gForceZOffset = 0.0
        gyroXOffset = 0.0
        gyroYOffset = 0.0
        gyroZOffset = 0.0
    }
    
    func applyGForceCalibration(x: Double, y: Double, z: Double) -> (x: Double, y: Double, z: Double) {
        return (x: x + gForceXOffset, y: y + gForceYOffset, z: z + gForceZOffset)
    }
    
    func applyGyroCalibration(x: Double, y: Double, z: Double) -> (x: Double, y: Double, z: Double) {
        return (x: x + gyroXOffset, y: y + gyroYOffset, z: z + gyroZOffset)
    }
    
    // MARK: - Accelerometer Orientation Detection
    
    /// Detect accelerometer orientation based on current readings during forward motion
    /// Call this while the device is experiencing forward acceleration (e.g., during a launch)
    /// - Parameters:
    ///   - x: Current X-axis acceleration (g)
    ///   - y: Current Y-axis acceleration (g)
    ///   - z: Current Z-axis acceleration (g)
    ///   - speed: Current speed (m/s) - should be increasing for forward detection
    func detectOrientation(x: Double, y: Double, z: Double, speed: Double) {
        // Only detect orientation when moving and accelerating
        guard speed > 2.0 else { return }  // At least 2 m/s (~4.5 mph)
        
        // Find which axis has the strongest positive or negative value (excluding gravity)
        // Gravity is typically -1g on the "up" axis when stationary
        // Forward acceleration will show positive values on the forward axis
        
        let absX = abs(x)
        let absY = abs(y)
        let absZ = abs(z - 1.0)  // Subtract gravity component
        
        // Determine which axis is "forward" based on strongest acceleration
        if absX > absY && absX > absZ && absX > 0.3 {  // At least 0.3g acceleration
            forwardAxis = "X"
            forwardDirection = x > 0 ? 1 : -1
            // Set perpendicular axes
            rightAxis = "Y"
            rightDirection = 1
            upAxis = "Z"
            upDirection = 1
            accelOrientationDetected = true
        } else if absY > absX && absY > absZ && absY > 0.3 {
            forwardAxis = "Y"
            forwardDirection = y > 0 ? 1 : -1
            // Set perpendicular axes
            rightAxis = "X"
            rightDirection = -1  // Right-hand rule
            upAxis = "Z"
            upDirection = 1
            accelOrientationDetected = true
        } else if absZ > absX && absZ > absY && absZ > 0.3 {
            forwardAxis = "Z"
            forwardDirection = (z - 1.0) > 0 ? 1 : -1
            // Set perpendicular axes
            rightAxis = "X"
            rightDirection = 1
            upAxis = "Y"
            upDirection = 1
            accelOrientationDetected = true
        }
    }
    
    /// Manually reset orientation to default (X forward, Y right, Z up)
    func resetOrientation() {
        forwardAxis = "X"
        forwardDirection = 1
        rightAxis = "Y"
        rightDirection = 1
        upAxis = "Z"
        upDirection = 1
        accelOrientationDetected = false
    }
    
    /// Apply orientation mapping to get vehicle-relative accelerations
    /// Returns (forward, right, up) in g's relative to vehicle motion
    func applyOrientationMapping(x: Double, y: Double, z: Double) -> (forward: Double, right: Double, up: Double) {
        // First apply calibration
        let calibrated = applyGForceCalibration(x: x, y: y, z: z)
        
        // Then apply orientation mapping
        let forward: Double
        let right: Double
        let up: Double
        
        switch forwardAxis {
        case "X":
            forward = calibrated.x * Double(forwardDirection)
        case "Y":
            forward = calibrated.y * Double(forwardDirection)
        case "Z":
            forward = calibrated.z * Double(forwardDirection)
        default:
            forward = calibrated.x
        }
        
        switch rightAxis {
        case "X":
            right = calibrated.x * Double(rightDirection)
        case "Y":
            right = calibrated.y * Double(rightDirection)
        case "Z":
            right = calibrated.z * Double(rightDirection)
        default:
            right = calibrated.y
        }
        
        switch upAxis {
        case "X":
            up = calibrated.x * Double(upDirection)
        case "Y":
            up = calibrated.y * Double(upDirection)
        case "Z":
            up = calibrated.z * Double(upDirection)
        default:
            up = calibrated.z
        }
        
        return (forward: forward, right: right, up: up)
    }
    
    /// Get orientation status message
    var orientationStatus: String {
        if accelOrientationDetected {
            let fwdSign = forwardDirection > 0 ? "+" : "-"
            let rightSign = rightDirection > 0 ? "+" : "-"
            let upSign = upDirection > 0 ? "+" : "-"
            return "Detected: Forward=\(fwdSign)\(forwardAxis), Right=\(rightSign)\(rightAxis), Up=\(upSign)\(upAxis)"
        } else {
            return "Not detected - accelerate forward to detect"
        }
    }
}

// MARK: - Speed Unit Enum

enum SpeedUnit: String, CaseIterable, Identifiable {
    case metersPerSecond = "m/s"
    case kilometersPerHour = "kph"
    case milesPerHour = "mph"
    case knots = "knots"
    
    var id: String { rawValue }
    
    var label: String {
        rawValue
    }
    
    func convert(_ speedInMetersPerSecond: Double) -> Double {
        switch self {
        case .metersPerSecond:
            return speedInMetersPerSecond
        case .kilometersPerHour:
            return speedInMetersPerSecond * 3.6
        case .milesPerHour:
            return speedInMetersPerSecond * 2.23694
        case .knots:
            return speedInMetersPerSecond * 1.94384
        }
    }
}

// MARK: - Altitude Unit Enum

enum AltitudeUnit: String, CaseIterable, Identifiable {
    case meters = "m"
    case feet = "ft"
    
    var id: String { rawValue }
    
    var label: String {
        rawValue
    }
    
    func convert(_ altitudeInMeters: Double) -> Double {
        switch self {
        case .meters:
            return altitudeInMeters
        case .feet:
            return altitudeInMeters * 3.28084
        }
    }
}

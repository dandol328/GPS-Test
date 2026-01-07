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

//
//  LocationSample.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// A single location/telemetry sample with comprehensive GNSS metadata
struct LocationSample: Codable, Identifiable {
    let id: UUID
    
    // Core position data
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let timestamp: Date
    
    // Accuracy metrics
    let horizontalAccuracy: Double  // meters
    let verticalAccuracy: Double?   // meters
    
    // Motion data
    let speed: Double              // m/s
    let speedAccuracy: Double?     // m/s
    let heading: Double?           // degrees (0-360)
    let headingAccuracy: Double?   // degrees
    
    // GNSS quality indicators
    let fixType: FixType
    let ageOfFix: TimeInterval?    // seconds since fix timestamp
    let satellites: Int?
    let hdop: Double?              // Horizontal Dilution of Precision
    let vdop: Double?              // Vertical Dilution of Precision
    let pdop: Double?              // Position Dilution of Precision
    
    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        timestamp: Date,
        horizontalAccuracy: Double,
        verticalAccuracy: Double?,
        speed: Double,
        speedAccuracy: Double?,
        heading: Double?,
        headingAccuracy: Double?,
        fixType: FixType,
        ageOfFix: TimeInterval?,
        satellites: Int?,
        hdop: Double?,
        vdop: Double?,
        pdop: Double?
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.heading = heading
        self.headingAccuracy = headingAccuracy
        self.fixType = fixType
        self.ageOfFix = ageOfFix
        self.satellites = satellites
        self.hdop = hdop
        self.vdop = vdop
        self.pdop = pdop
    }
    
    /// Create a LocationSample from BLE data
    /// Note: BLE protocol doesn't provide all accuracy fields, so we estimate them from PDOP
    static func fromBLE(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        speed: Double,
        heading: Double,
        fixStatus: Int,
        satellites: Int,
        pdop: Double,
        timestamp: Date = Date()
    ) -> LocationSample {
        let fixType = FixType.from(bleFixStatus: fixStatus)
        
        // Estimate horizontal accuracy from PDOP
        // Rule of thumb: horizontalAccuracy ≈ PDOP * 5 meters for consumer GPS
        // Better PDOP (lower value) = better accuracy
        // NOTE: This is a rough estimation specific to BLE data conversion.
        //       Actual accuracy varies significantly by GPS receiver and environmental conditions.
        let estimatedHorizontalAccuracy: Double
        if pdop > 0 {
            estimatedHorizontalAccuracy = pdop * 5.0
        } else {
            estimatedHorizontalAccuracy = 50.0  // Default for unknown
        }
        
        // Estimate vertical accuracy (typically worse than horizontal)
        let estimatedVerticalAccuracy = estimatedHorizontalAccuracy * 1.5
        
        // Estimate speed accuracy (for high-quality GNSS, ~0.1 m/s; for consumer GPS, ~0.3-0.5 m/s)
        let estimatedSpeedAccuracy: Double
        if pdop < 2.0 {
            estimatedSpeedAccuracy = 0.2
        } else if pdop < 5.0 {
            estimatedSpeedAccuracy = 0.4
        } else {
            estimatedSpeedAccuracy = 0.8
        }
        
        // Estimate heading accuracy
        let estimatedHeadingAccuracy: Double?
        if speed > 1.0 {  // Only trust heading when moving
            estimatedHeadingAccuracy = pdop < 3.0 ? 5.0 : 15.0
        } else {
            estimatedHeadingAccuracy = nil
        }
        
        // Estimate HDOP and VDOP from PDOP
        // Typical relationship: PDOP^2 ≈ HDOP^2 + VDOP^2
        // Assume HDOP ≈ 0.7 * PDOP and VDOP ≈ 0.7 * PDOP (simplified)
        let estimatedHdop = pdop * 0.7
        let estimatedVdop = pdop * 0.7
        
        return LocationSample(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            timestamp: timestamp,
            horizontalAccuracy: estimatedHorizontalAccuracy,
            verticalAccuracy: estimatedVerticalAccuracy,
            speed: speed,
            speedAccuracy: estimatedSpeedAccuracy,
            heading: heading,
            headingAccuracy: estimatedHeadingAccuracy,
            fixType: fixType,
            ageOfFix: 0.0,  // Assume recent for BLE data
            satellites: satellites,
            hdop: estimatedHdop,
            vdop: estimatedVdop,
            pdop: pdop
        )
    }
}

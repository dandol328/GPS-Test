//
//  BLEManager.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//  

import CoreBluetooth
import Foundation

class BLEManager: NSObject, ObservableObject {
    // Connection state enum for clearer state management
    private enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
    }
    
    // RaceBox Protocol Constants
    private struct ProtocolConstants {
        // Frame start bytes (UBX-like protocol)
        static let frameStartByte1: UInt8 = 0xB5
        static let frameStartByte2: UInt8 = 0x62
        
        // Message identifiers for RaceBox Data Message
        static let messageClass: UInt8 = 0xFF
        static let messageId: UInt8 = 0x01
        
        // Packet size (2 header + 2 class/id + 2 length + 80 payload + 2 checksum)
        static let packetSize = 88
        
        // GPS data absolute offsets in the full packet (payload offset + 6)
        // (payload offsets come from BluetoothProtocol.txt; payload starts at absolute index 6)
        static let numSatellitesOffset = 29   // payload 23 + 6
        static let longitudeOffset = 30       // payload 24 + 6
        static let latitudeOffset = 34        // payload 28 + 6
        static let altitudeOffset = 38        // payload 32 + 6
        
        // Motion offsets (absolute)
        static let speedOffset = 54           // payload 48 + 6
        static let headingOffset = 58         // payload 52 + 6
        
        // IMU offsets (absolute)
        static let accelerometerXOffset = 74  // payload 68 + 6
        static let accelerometerYOffset = 76  // payload 70 + 6
        static let accelerometerZOffset = 78  // payload 72 + 6
        static let gyroscopeXOffset = 80      // payload 74 + 6
        static let gyroscopeYOffset = 82      // payload 76 + 6
        static let gyroscopeZOffset = 84      // payload 78 + 6
        
        // Conversion factor for GPS coordinates
        static let coordinateScale = 10_000_000.0
        static let altitudeScale = 1000.0  // mm to meters
        static let speedScale = 1000.0  // mm/s to m/s
        static let headingScale = 100_000.0  // degrees * 1e5 (protocol uses factor 1e5)
        
        // Device name prefix for filtering
        static let deviceNamePrefix = "RaceBox"
    }
    
    // Published properties for UI updates
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var numSatellites: Int = 0
    @Published var altitude: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var accelerometerX: Double = 0.0
    @Published var accelerometerY: Double = 0.0
    @Published var accelerometerZ: Double = 0.0
    @Published var gyroscopeX: Double = 0.0
    @Published var gyroscopeY: Double = 0.0
    @Published var gyroscopeZ: Double = 0.0
    
    // ... rest of class (parsing code unchanged aside from using the above constants)
    
    // Example parsing snippet (unchanged; shown for context)
    private func parsePacket(_ data: Data) {
        guard data.count >= ProtocolConstants.packetSize else { return }
        
        let numSV = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.numSatellitesOffset, as: UInt8.self)
        }
        
        let longitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.longitudeOffset, as: Int32.self)
        }
        let latitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.latitudeOffset, as: Int32.self)
        }
        let altitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.altitudeOffset, as: Int32.self)
        }
        let speedRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.speedOffset, as: Int32.self)
        }
        let headingRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.headingOffset, as: Int32.self)
        }
        
        let accelX = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerXOffset, as: Int16.self)
        }
        let accelY = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerYOffset, as: Int16.self)
        }
        let accelZ = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerZOffset, as: Int16.self)
        }
        
        let gyroX = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeXOffset, as: Int16.self)
        }
        let gyroY = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeYOffset, as: Int16.self)
        }
        let gyroZ = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeZOffset, as: Int16.self)
        }
        
        // Convert to appropriate units
        let newLongitude = Double(longitudeRaw) / ProtocolConstants.coordinateScale
        let newLatitude = Double(latitudeRaw) / ProtocolConstants.coordinateScale
        let newAltitude = Double(altitudeRaw) / ProtocolConstants.altitudeScale
        let newSpeed = Double(speedRaw) / ProtocolConstants.speedScale
        let newHeading = Double(headingRaw) / ProtocolConstants.headingScale
        
        // Accelerometer: milli-g -> g
        let newAccelX = Double(accelX) / 1000.0
        let newAccelY = Double(accelY) / 1000.0
        let newAccelZ = Double(accelZ) / 1000.0
        
        // Gyroscope: centi-deg/s -> deg/s
        let newGyroX = Double(gyroX) / 100.0
        let newGyroY = Double(gyroY) / 100.0
        let newGyroZ = Double(gyroZ) / 100.0
        
        DispatchQueue.main.async {
            self.longitude = newLongitude
            self.latitude = newLatitude
            self.numSatellites = Int(numSV)
            self.altitude = newAltitude
            self.speed = newSpeed
            self.heading = newHeading
            self.accelerometerX = newAccelX
            self.accelerometerY = newAccelY
            self.accelerometerZ = newAccelZ
            self.gyroscopeX = newGyroX
            self.gyroscopeY = newGyroY
            self.gyroscopeZ = newGyroZ
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    // ... rest of file unchanged
}

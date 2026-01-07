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
        
        // Packet size
        static let packetSize = 88
        
        // GPS data offsets in the packet
        static let numSatellitesOffset = 23
        static let longitudeOffset = 24
        static let latitudeOffset = 28
        static let altitudeOffset = 32
        static let speedOffset = 48
        static let headingOffset = 52
        static let accelerometerXOffset = 68
        static let accelerometerYOffset = 70
        static let accelerometerZOffset = 72
        static let gyroscopeXOffset = 74
        static let gyroscopeYOffset = 76
        static let gyroscopeZOffset = 78
        
        // Conversion factor for GPS coordinates
        static let coordinateScale = 10_000_000.0
        static let altitudeScale = 1000.0  // mm to meters
        static let speedScale = 1000.0  // mm/s to m/s
        static let headingScale = 100_000.0  // degrees * 1e-5
        
        // Device name prefix for filtering
        static let deviceNamePrefix = "RaceBox"
    }
    
    // Published properties for UI updates
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var numSatellites: Int = 0
    @Published var speed: Double = 0.0  // m/s
    @Published var altitude: Double = 0.0  // meters
    @Published var heading: Double = 0.0  // degrees
    @Published var accelerometerX: Double = 0.0  // milli-g
    @Published var accelerometerY: Double = 0.0  // milli-g
    @Published var accelerometerZ: Double = 0.0  // milli-g
    @Published var gyroscopeX: Double = 0.0  // centi-deg/s
    @Published var gyroscopeY: Double = 0.0  // centi-deg/s
    @Published var gyroscopeZ: Double = 0.0  // centi-deg/s
    @Published var isConnected: Bool = false
    @Published var isScanning: Bool = false
    @Published var statusMessage: String = "Ready to connect"
    
    // BLE UUIDs for RaceBox Mini
    private let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var connectionState: ConnectionState = .disconnected
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth is not available"
            return
        }
        
        connectionState = .scanning
        isScanning = true
        statusMessage = "Scanning for RaceBox..."
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
        // Only update state to disconnected if we were actually scanning
        if connectionState == .scanning {
            connectionState = .disconnected
        }
        isScanning = false
    }
    
    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    private func parseGPSData(_ data: Data) {
        // Ensure we have the complete RaceBox Data Message packet
        guard data.count >= ProtocolConstants.packetSize else {
            return
        }
        
        // Convert Data to byte array for header validation
        let bytes = [UInt8](data)
        
        // Check for valid frame start
        guard bytes[0] == ProtocolConstants.frameStartByte1,
              bytes[1] == ProtocolConstants.frameStartByte2 else {
            return
        }
        
        // Check message class and ID for RaceBox Data Message
        guard bytes[2] == ProtocolConstants.messageClass,
              bytes[3] == ProtocolConstants.messageId else {
            return
        }
        
        // Debug: Print received data
        print("Received GPS data: \(bytes.count) bytes")
        print("Hex dump: \(bytes.map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // Extract number of satellites (1 byte, unsigned)
        let numSV = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.numSatellitesOffset, as: UInt8.self)
        }
        
        // Extract longitude (4 bytes, little-endian int32)
        let longitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.longitudeOffset, as: Int32.self)
        }
        
        // Extract latitude (4 bytes, little-endian int32)
        let latitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.latitudeOffset, as: Int32.self)
        }
        
        // Extract altitude (4 bytes, little-endian int32, in mm)
        let altitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.altitudeOffset, as: Int32.self)
        }
        
        // Extract speed (4 bytes, little-endian int32, in mm/s)
        let speedRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.speedOffset, as: Int32.self)
        }
        
        // Extract heading (4 bytes, little-endian int32, in degrees * 1e-5)
        let headingRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.headingOffset, as: Int32.self)
        }
        
        // Extract accelerometer data (3 x 2 bytes, little-endian int16, in milli-g)
        let accelX = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerXOffset, as: Int16.self)
        }
        let accelY = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerYOffset, as: Int16.self)
        }
        let accelZ = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.accelerometerZOffset, as: Int16.self)
        }
        
        // Extract gyroscope data (3 x 2 bytes, little-endian int16, in centi-deg/s)
        let gyroX = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeXOffset, as: Int16.self)
        }
        let gyroY = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeYOffset, as: Int16.self)
        }
        let gyroZ = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.gyroscopeZOffset, as: Int16.self)
        }
        
        // Debug logging of raw values
        print("Raw numSatellites: \(numSV)")
        print("Raw longitude: \(longitudeRaw), latitude: \(latitudeRaw)")
        print("Raw altitude: \(altitudeRaw) mm")
        print("Raw speed: \(speedRaw) mm/s")
        print("Raw heading: \(headingRaw) (degrees * 1e-5)")
        print("Raw accel: X=\(accelX), Y=\(accelY), Z=\(accelZ) milli-g")
        print("Raw gyro: X=\(gyroX), Y=\(gyroY), Z=\(gyroZ) centi-deg/s")
        
        // Convert to appropriate units
        let newLongitude = Double(longitudeRaw) / ProtocolConstants.coordinateScale
        let newLatitude = Double(latitudeRaw) / ProtocolConstants.coordinateScale
        let newAltitude = Double(altitudeRaw) / ProtocolConstants.altitudeScale
        let newSpeed = Double(speedRaw) / ProtocolConstants.speedScale
        let newHeading = Double(headingRaw) / ProtocolConstants.headingScale
        
        // Debug converted values
        print("Converted: altitude=\(newAltitude)m, speed=\(newSpeed)m/s, heading=\(newHeading)°")
        print("---")
        
        // Update on main thread
        DispatchQueue.main.async {
            self.longitude = newLongitude
            self.latitude = newLatitude
            self.numSatellites = Int(numSV)
            self.altitude = newAltitude
            self.speed = newSpeed
            self.heading = newHeading
            self.accelerometerX = Double(accelX)
            self.accelerometerY = Double(accelY)
            self.accelerometerZ = Double(accelZ)
            self.gyroscopeX = Double(gyroX)
            self.gyroscopeY = Double(gyroY)
            self.gyroscopeZ = Double(gyroZ)
        }
    }
}
// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is ready"
        case .poweredOff:
            statusMessage = "Bluetooth is off"
        case .unauthorized:
            statusMessage = "Bluetooth access denied"
        case .unsupported:
            statusMessage = "Bluetooth not supported"
        default:
            statusMessage = "Bluetooth unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Prevent race conditions: only connect if we're in scanning state
        guard connectionState == .scanning else {
            return
        }
        
        // Filter devices by name: only connect to devices with RaceBox prefix
        // This ensures compatibility with RaceBox Mini and other RaceBox devices
        // NOTE: If multiple RaceBox devices are in range, this will connect to the first one discovered.
        // Future enhancement: Consider implementing device selection UI or using RSSI to select strongest signal.
        if let name = peripheral.name, name.hasPrefix(ProtocolConstants.deviceNamePrefix) {
            connectionState = .connecting
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.stopScan()
            isScanning = false
            statusMessage = "Connecting to \(name)..."
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        statusMessage = "Connected! Discovering services..."
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        statusMessage = "Disconnected"
        isConnected = false
        self.peripheral = nil
        self.txCharacteristic = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        statusMessage = "Failed to connect"
        isConnected = false
    }
}
// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            statusMessage = "Error discovering services: \(error.localizedDescription)"
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID {
                    peripheral.discoverCharacteristics([txCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            statusMessage = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == txCharacteristicUUID {
                    txCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    statusMessage = "Receiving GPS data at 25Hz"
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            return
        }
        
        parseGPSData(data)
    }
}
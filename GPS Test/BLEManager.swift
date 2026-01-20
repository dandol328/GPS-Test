//
//
//  BLEManager.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//  

import CoreBluetooth
import Foundation

struct DiscoveredDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int?
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
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
        static let fixStatusOffset = 26       // payload 20 + 6
        static let fixStatusFlagsOffset = 27  // payload 21 + 6
        static let numSatellitesOffset = 29   // payload 23 + 6
        static let longitudeOffset = 30       // payload 24 + 6
        static let latitudeOffset = 34        // payload 28 + 6
        static let altitudeOffset = 38        // payload 32 + 6
        
        // Motion offsets (absolute)
        static let speedOffset = 54           // payload 48 + 6
        static let headingOffset = 58         // payload 52 + 6
        
        // Additional GPS quality offsets
        static let pdopOffset = 70            // payload 64 + 6
        static let batteryStatusOffset = 73   // payload 67 + 6
        
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
        static let pdopScale = 100.0  // PDOP with factor of 100
        
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
    @Published var isConnected: Bool = false
    @Published var isScanning: Bool = false
    @Published var statusMessage: String = "Disconnected"
    
    // Additional GPS quality metrics
    @Published var fixStatus: Int = 0  // 0=no fix, 2=2D, 3=3D
    @Published var fixStatusFlags: UInt8 = 0
    @Published var pdop: Double = 0.0
    @Published var batteryLevel: Int = 0  // 0-100%
    @Published var isCharging: Bool = false
    @Published var updateRate: Double = 0.0  // Hz
    @Published var connectedDeviceName: String = ""
    @Published var discoveredDevices: [DiscoveredDevice] = []
    
    // Data rate tracking
    private var lastUpdateTime: Date?
    private var updateIntervals: [TimeInterval] = []
    private let maxIntervalSamples = 10
    
    // BLE properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var peripheralsByID: [UUID: CBPeripheral] = [:]
    private var txCharacteristic: CBCharacteristic?
    private var connectionState: ConnectionState = .disconnected
    
    // Service and Characteristic UUIDs (from RaceBox protocol)
    private let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard connectionState == .disconnected else { return }
        guard centralManager.state == .poweredOn else {
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth not available"
            }
            return
        }
        
        connectionState = .scanning
        peripheralsByID.removeAll()
        DispatchQueue.main.async { self.discoveredDevices.removeAll() }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.statusMessage = "Scanning for RaceBox..."
        }
        
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
        if connectionState == .scanning { connectionState = .disconnected }
        DispatchQueue.main.async {
            self.isScanning = false
            if !self.isConnected {
                if self.discoveredDevices.isEmpty {
                    self.statusMessage = "No devices found"
                } else {
                    self.statusMessage = "Scan stopped"
                }
            }
        }
    }
    
    func connect(to device: DiscoveredDevice) {
        guard let peripheral = peripheralsByID[device.id] else { return }
        centralManager.stopScan()
        connectionState = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        DispatchQueue.main.async {
            self.isScanning = false
            self.statusMessage = "Connecting to \(device.name)..."
        }
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionState = .disconnected
        DispatchQueue.main.async {
            self.isConnected = false
            self.isScanning = false
            self.statusMessage = "Disconnected"
            self.connectedDeviceName = ""
        }
    }
    
    // ... rest of class (parsing code unchanged aside from using the above constants)
    
    // Example parsing snippet (unchanged; shown for context)
    private func parsePacket(_ data: Data) {
        guard data.count >= ProtocolConstants.packetSize else { return }
        
        // Track update rate
        let now = Date()
        if let lastTime = lastUpdateTime {
            let interval = now.timeIntervalSince(lastTime)
            updateIntervals.append(interval)
            if updateIntervals.count > maxIntervalSamples {
                updateIntervals.removeFirst()
            }
            if !updateIntervals.isEmpty {
                let avgInterval = updateIntervals.reduce(0, +) / Double(updateIntervals.count)
                let hz = avgInterval > 0 ? 1.0 / avgInterval : 0.0
                DispatchQueue.main.async {
                    self.updateRate = hz
                }
            }
        }
        lastUpdateTime = now
        
        let fixStat = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.fixStatusOffset, as: UInt8.self)
        }
        
        let fixFlags = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.fixStatusFlagsOffset, as: UInt8.self)
        }
        
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
        
        let pdopRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.pdopOffset, as: UInt16.self)
        }
        
        let batteryRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: ProtocolConstants.batteryStatusOffset, as: UInt8.self)
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
        let newPdop = Double(pdopRaw) / ProtocolConstants.pdopScale
        
        // Battery: MSB is charging status, lower 7 bits are percentage
        let charging = (batteryRaw & 0x80) != 0
        let batteryPercent = Int(batteryRaw & 0x7F)
        
        // Accelerometer: milli-g -> g
        let newAccelX = Double(accelX) / 1000.0
        let newAccelY = Double(accelY) / 1000.0
        let newAccelZ = Double(accelZ) / 1000.0
        
        // Gyroscope: centi-deg/s -> deg/s
        let newGyroX = Double(gyroX) / 100.0
        let newGyroY = Double(gyroY) / 100.0
        let newGyroZ = Double(gyroZ) / 100.0
        
        DispatchQueue.main.async {
            self.fixStatus = Int(fixStat)
            self.fixStatusFlags = fixFlags
            self.longitude = newLongitude
            self.latitude = newLatitude
            self.numSatellites = Int(numSV)
            self.altitude = newAltitude
            self.speed = newSpeed
            self.heading = newHeading
            self.pdop = newPdop
            self.batteryLevel = batteryPercent
            self.isCharging = charging
            self.accelerometerX = newAccelX
            self.accelerometerY = newAccelY
            self.accelerometerZ = newAccelZ
            self.gyroscopeX = newGyroX
            self.gyroscopeY = newGyroY
            self.gyroscopeZ = newGyroZ
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth ready"
            }
        case .poweredOff:
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth is off"
            }
        case .unauthorized:
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth unauthorized"
            }
        case .unsupported:
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth not supported"
            }
        default:
            DispatchQueue.main.async {
                self.statusMessage = "Bluetooth unavailable"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check if device name starts with "RaceBox"
        guard let name = peripheral.name, name.hasPrefix(ProtocolConstants.deviceNamePrefix) else {
            return
        }

        // Track peripheral by ID for later connection
        peripheralsByID[peripheral.identifier] = peripheral

        let id = peripheral.identifier
        let device = DiscoveredDevice(id: id, name: name, rssi: RSSI.intValue)

        // Update or insert discovered device
        DispatchQueue.main.async {
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == id }) {
                self.discoveredDevices[index] = device
            } else {
                self.discoveredDevices.append(device)
            }
            if self.isScanning {
                let count = self.discoveredDevices.count
                self.statusMessage = count == 1 ? "Found 1 device" : "Found \(count) devices"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        DispatchQueue.main.async {
            self.isConnected = true
            self.statusMessage = "Connected"
            self.connectedDeviceName = peripheral.name ?? "Unknown"
        }
        
        // Discover services
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isScanning = false
            self.statusMessage = "Failed to connect"
            self.connectedDeviceName = ""
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
        txCharacteristic = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isScanning = false
            self.statusMessage = "Disconnected"
            self.connectedDeviceName = ""
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([txCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == txCharacteristicUUID {
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                DispatchQueue.main.async {
                    self.statusMessage = "Receiving data"
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == txCharacteristicUUID,
              let data = characteristic.value else {
            return
        }
        
        parsePacket(data)
    }
}


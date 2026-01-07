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
    
    // Published properties for UI updates
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
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
        // Ensure we have at least 88 bytes (RaceBox Data Message packet size)
        // This validates that offsets 0-87 are safe to access
        guard data.count >= 88 else {
            return
        }
        
        // Convert Data to byte array for header validation
        let bytes = [UInt8](data)
        
        // Check for valid frame start (0xB5 0x62)
        guard bytes[0] == 0xB5 && bytes[1] == 0x62 else {
            return
        }
        
        // Check message class (0xFF) and message ID (0x01) for RaceBox Data Message
        guard bytes[2] == 0xFF && bytes[3] == 0x01 else {
            return
        }
        
        // Extract longitude (offset 30-33, 4 bytes, little-endian int32)
        // Bounds already validated by 88-byte check above
        let longitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: 30, as: Int32.self)
        }
        
        // Extract latitude (offset 34-37, 4 bytes, little-endian int32)
        // Bounds already validated by 88-byte check above
        let latitudeRaw = data.withUnsafeBytes { buffer in
            buffer.loadUnaligned(fromByteOffset: 34, as: Int32.self)
        }
        
        // Convert to degrees (divide by 10^7)
        let newLongitude = Double(longitudeRaw) / 10_000_000.0
        let newLatitude = Double(latitudeRaw) / 10_000_000.0
        
        // Update on main thread
        DispatchQueue.main.async {
            self.longitude = newLongitude
            self.latitude = newLatitude
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
        
        // Filter devices by name: only connect to devices starting with "RaceBox"
        // This ensures compatibility with RaceBox Mini and other RaceBox devices
        // If multiple RaceBox devices are found, the first discovered device is selected
        if let name = peripheral.name, name.hasPrefix("RaceBox") {
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
        guard error == nil else {
            statusMessage = "Error discovering services"
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
        guard error == nil else {
            statusMessage = "Error discovering characteristics"
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

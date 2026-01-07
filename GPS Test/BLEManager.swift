//
//  BLEManager.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import CoreBluetooth
import Foundation

class BLEManager: NSObject, ObservableObject {
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
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth is not available"
            return
        }
        
        isScanning = true
        statusMessage = "Scanning for RaceBox..."
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    private func parseGPSData(_ data: Data) {
        // Ensure we have at least 80 bytes (minimum for GPS data packet)
        guard data.count >= 80 else {
            return
        }
        
        // Convert Data to byte array
        let bytes = [UInt8](data)
        
        // Check for valid frame start (0xB5 0x62)
        guard bytes[0] == 0xB5 && bytes[1] == 0x62 else {
            return
        }
        
        // Check message class (0xFF) and message ID (0x01) for RaceBox Data Message
        guard bytes[2] == 0xFF && bytes[3] == 0x01 else {
            return
        }
        
        // Extract longitude (offset 30, 4 bytes, little-endian int32)
        let longitudeRaw = Int32(bytes[30]) |
                          (Int32(bytes[31]) << 8) |
                          (Int32(bytes[32]) << 16) |
                          (Int32(bytes[33]) << 24)
        
        // Extract latitude (offset 34, 4 bytes, little-endian int32)
        let latitudeRaw = Int32(bytes[34]) |
                         (Int32(bytes[35]) << 8) |
                         (Int32(bytes[36]) << 16) |
                         (Int32(bytes[37]) << 24)
        
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
        // Check if the device name starts with "RaceBox"
        if let name = peripheral.name, name.hasPrefix("RaceBox") {
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.stopScan()
            isScanning = false
            statusMessage = "Connecting to \(name)..."
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Connected! Discovering services..."
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Disconnected"
        isConnected = false
        self.peripheral = nil
        self.txCharacteristic = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
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

//
//  SettingsView.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settings: UserSettings
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Connection Section
                Section(header: Text("Connection")) {
                    HStack {
                        Circle()
                            .fill(bleManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(bleManager.statusMessage)
                            .foregroundColor(.secondary)
                    }
                    
                    if !bleManager.isConnected {
                        Button(action: {
                            bleManager.startScanning()
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text(bleManager.isScanning ? "Scanning..." : "Connect to RaceBox")
                            }
                        }
                        .disabled(bleManager.isScanning)
                    } else {
                        Button(action: {
                            bleManager.disconnect()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - Units Section
                Section(header: Text("Units")) {
                    Picker("Speed", selection: $settings.speedUnit) {
                        ForEach(SpeedUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    
                    Picker("Altitude", selection: $settings.altitudeUnit) {
                        ForEach(AltitudeUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                }
                
                // MARK: - Calibration Section
                Section(header: Text("Calibration"), footer: Text("Zero the sensors while the device is stationary and level.")) {
                    Button(action: {
                        settings.calibrateGForce(
                            x: bleManager.accelerometerX,
                            y: bleManager.accelerometerY,
                            z: bleManager.accelerometerZ
                        )
                    }) {
                        HStack {
                            Image(systemName: "gyroscope")
                            Text("Zero G-Force")
                        }
                    }
                    .disabled(!bleManager.isConnected)
                    
                    Button(action: {
                        settings.calibrateGyroscope(
                            x: bleManager.gyroscopeX,
                            y: bleManager.gyroscopeY,
                            z: bleManager.gyroscopeZ
                        )
                    }) {
                        HStack {
                            Image(systemName: "rotate.3d")
                            Text("Zero Gyroscope")
                        }
                    }
                    .disabled(!bleManager.isConnected)
                    
                    Button(action: {
                        settings.resetCalibration()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Calibration")
                        }
                    }
                    .foregroundColor(.orange)
                }
                
                // MARK: - About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(bleManager: BLEManager(), settings: UserSettings())
}

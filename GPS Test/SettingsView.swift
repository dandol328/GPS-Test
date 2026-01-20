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
    @ObservedObject var sessionManager: SessionManager
    @State private var showingClearSessionsAlert = false
    
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
                        Button {
                            bleManager.startScanning()
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text(bleManager.isScanning ? "Scanning..." : "Scan for Devices")
                            }
                        }
                        .disabled(bleManager.isScanning)
                        
                        if bleManager.isScanning && bleManager.discoveredDevices.isEmpty {
                            Text("Scanning for nearby devices...")
                                .foregroundColor(.secondary)
                        }

                        ForEach(bleManager.discoveredDevices, id: \.id) { device in
                            Button {
                                bleManager.connect(to: device)
                            } label: {
                                HStack {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                    Text(device.name.isEmpty ? "Unnamed" : device.name)
                                    Spacer()
                                    if let rssi = device.rssi {
                                        Text("\(rssi) dBm")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        if bleManager.isScanning {
                            Button {
                                bleManager.stopScanning()
                            } label: {
                                HStack {
                                    Image(systemName: "stop.circle")
                                    Text("Stop Scanning")
                                }
                            }
                        }
                    } else {
                        Button {
                            bleManager.disconnect()
                        } label: {
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
                
                // MARK: - Orientation Section
                Section(header: Text("Accelerometer Orientation"), 
                       footer: Text(settings.orientationStatus)) {
                    Button(action: {
                        settings.detectOrientation(
                            x: bleManager.accelerometerX,
                            y: bleManager.accelerometerY,
                            z: bleManager.accelerometerZ,
                            speed: bleManager.speed
                        )
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.forward")
                            Text("Detect Orientation")
                        }
                    }
                    .disabled(!bleManager.isConnected || bleManager.speed < 2.0)
                    
                    Button(action: {
                        settings.resetOrientation()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Default (X Forward)")
                        }
                    }
                    .foregroundColor(.orange)
                    
                    if settings.accelOrientationDetected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Orientation Detected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Session Storage Section
                Section(header: Text("Session Storage"), 
                       footer: Text("Stored sessions: \(sessionManager.sessions.count) / 50")) {
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(sessionManager.sessions.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !sessionManager.sessions.isEmpty {
                        Button(action: {
                            showingClearSessionsAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Sessions")
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - Recording Settings Section
                Section(header: Text("Recording Settings"),
                       footer: Text("Sample rate limited to 25 Hz by BLE device. Accuracy threshold affects metric reliability indicators.")) {
                    HStack {
                        Text("Sample Rate")
                        Spacer()
                        Text("\(settings.sampleRateHz) Hz")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("Accuracy Threshold: \(Int(settings.accuracyThreshold))m", 
                            value: $settings.accuracyThreshold, 
                            in: 10...100, 
                            step: 10)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Sessions", isPresented: $showingClearSessionsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    sessionManager.clearAllSessions()
                }
            } message: {
                Text("Are you sure you want to delete all \(sessionManager.sessions.count) recorded sessions? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView(bleManager: BLEManager(), settings: UserSettings(), sessionManager: SessionManager())
}


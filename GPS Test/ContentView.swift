//
//  ContentView.swift
//  GPS Test
//
//  Created by Dan on 1/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var settings = UserSettings()
    
    var body: some View {
        TabView {
            DashboardView(bleManager: bleManager, settings: settings)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
            
            MinMaxView(bleManager: bleManager, settings: settings)
                .tabItem {
                    Label("Min/Max", systemImage: "chart.bar")
                }
            
            PerformanceTimingView(bleManager: bleManager, settings: settings)
                .tabItem {
                    Label("Timing", systemImage: "timer")
                }
            
            SettingsView(bleManager: bleManager, settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settings: UserSettings
    @State private var pulseAnimation = false
    
    // Format string for GPS coordinates (7 decimal places)
    private let coordinateFormat = "%.7f°"
    
    var fixStatusText: String {
        switch bleManager.fixStatus {
        case 0:
            return "No Fix"
        case 2:
            return "2D Fix"
        case 3:
            return "3D Fix"
        default:
            return "Unknown"
        }
    }
    
    var fixStatusColor: Color {
        switch bleManager.fixStatus {
        case 3:
            return .green
        case 2:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(bleManager.isConnected ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                                .scaleEffect(pulseAnimation && bleManager.isConnected ? 1.2 : 1.0)
                                .opacity(pulseAnimation && bleManager.isConnected ? 0.6 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                                .onAppear {
                                    pulseAnimation = true
                                }
                            Text(bleManager.statusMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if bleManager.isConnected {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(String(format: "%.1f Hz", bleManager.updateRate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // GPS Fix Status
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(fixStatusColor)
                                    .frame(width: 8, height: 8)
                                Text(fixStatusText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            if bleManager.isConnected {
                                HStack(spacing: 4) {
                                    Image(systemName: bleManager.isCharging ? "battery.100.bolt" : "battery.100")
                                        .font(.caption)
                                    Text("\(bleManager.batteryLevel)%")
                                        .font(.caption)
                                }
                                .foregroundColor(bleManager.batteryLevel < 20 ? .red : .secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // GPS Position Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "GPS Position", icon: "location.fill")
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "Latitude",
                                value: String(format: coordinateFormat, bleManager.latitude),
                                icon: "location.north.line"
                            )
                            DataCard(
                                label: "Longitude",
                                value: String(format: coordinateFormat, bleManager.longitude),
                                icon: "location.circle"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "Altitude",
                                value: String(format: "%.1f %@", settings.convertAltitude(bleManager.altitude), settings.altitudeUnitLabel()),
                                icon: "mountain.2"
                            )
                            DataCard(
                                label: "Satellites",
                                value: "\(bleManager.numSatellites)",
                                icon: "dot.radiowaves.up.forward"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "PDOP",
                                value: String(format: "%.2f", bleManager.pdop),
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                    }
                    
                    // GPS Motion Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Motion", icon: "figure.run")
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "Speed",
                                value: String(format: "%.2f %@", settings.convertSpeed(bleManager.speed), settings.speedUnitLabel()),
                                icon: "speedometer"
                            )
                            DataCard(
                                label: "Heading",
                                value: String(format: "%.1f°", bleManager.heading),
                                icon: "location.north.circle"
                            )
                        }
                    }
                    
                    // Accelerometer Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Accelerometer (g)", icon: "gyroscope")
                        
                        let calibratedG = settings.applyGForceCalibration(
                            x: bleManager.accelerometerX,
                            y: bleManager.accelerometerY,
                            z: bleManager.accelerometerZ
                        )
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "Forward/Back (X)",
                                value: String(format: "%.3f g", calibratedG.x),
                                icon: "arrow.left.and.right"
                            )
                            DataCard(
                                label: "Left/Right (Y)",
                                value: String(format: "%.3f g", calibratedG.y),
                                icon: "arrow.up.and.down"
                            )
                            DataCard(
                                label: "Up/Down (Z)",
                                value: String(format: "%.3f g", calibratedG.z),
                                icon: "arrow.up.arrow.down"
                            )
                        }
                    }
                    
                    // Gyroscope Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Gyroscope (°/s)", icon: "rotate.3d")
                        
                        let calibratedGyro = settings.applyGyroCalibration(
                            x: bleManager.gyroscopeX,
                            y: bleManager.gyroscopeY,
                            z: bleManager.gyroscopeZ
                        )
                        
                        HStack(spacing: 12) {
                            DataCard(
                                label: "Roll (X)",
                                value: String(format: "%.2f °/s", calibratedGyro.x),
                                icon: "rotate.left"
                            )
                            DataCard(
                                label: "Pitch (Y)",
                                value: String(format: "%.2f °/s", calibratedGyro.y),
                                icon: "rotate.right"
                            )
                            DataCard(
                                label: "Yaw (Z)",
                                value: String(format: "%.2f °/s", calibratedGyro.z),
                                icon: "rotate.3d"
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("RaceBox GPS")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.headline)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DataCard: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    ContentView()
}

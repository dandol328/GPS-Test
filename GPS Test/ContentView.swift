//
//  ContentView.swift
//  GPS Test
//
//  Created by Dan on 1/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    // Format string for GPS coordinates (7 decimal places)
    private let coordinateFormat = "%.7f°"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("RaceBox GPS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Status indicator
            HStack {
                Circle()
                    .fill(bleManager.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(bleManager.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 20) {
                    // GPS Position Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "GPS Position")
                        
                        HStack(spacing: 12) {
                            DataCard(label: "Latitude", value: String(format: coordinateFormat, bleManager.latitude))
                            DataCard(label: "Longitude", value: String(format: coordinateFormat, bleManager.longitude))
                        }
                        
                        HStack(spacing: 12) {
                            DataCard(label: "Altitude", value: String(format: "%.1f m", bleManager.altitude))
                            DataCard(label: "Satellites", value: "\(bleManager.numSatellites)")
                        }
                    }
                    
                    // GPS Motion Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Motion")
                        
                        HStack(spacing: 12) {
                            DataCard(label: "Speed", value: String(format: "%.2f m/s", bleManager.speed))
                            DataCard(label: "Heading", value: String(format: "%.1f°", bleManager.heading))
                        }
                    }
                    
                    // Accelerometer Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Accelerometer (g)")
                        
                        HStack(spacing: 12) {
                            DataCard(label: "X", value: String(format: "%.3f g", bleManager.accelerometerX))
                            DataCard(label: "Y", value: String(format: "%.3f g", bleManager.accelerometerY))
                            DataCard(label: "Z", value: String(format: "%.3f g", bleManager.accelerometerZ))
                        }
                    }
                    
                    // Gyroscope Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "Gyroscope (°/s)")
                        
                        HStack(spacing: 12) {
                            DataCard(label: "Roll (X)", value: String(format: "%.2f °/s", bleManager.gyroscopeX))
                            DataCard(label: "Pitch (Y)", value: String(format: "%.2f °/s", bleManager.gyroscopeY))
                            DataCard(label: "Yaw (Z)", value: String(format: "%.2f °/s", bleManager.gyroscopeZ))
                        }
                    }
                    
                    // Connect/Disconnect buttons and other UI omitted for brevity...
                }
                .padding()
            }
        }
        .padding()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DataCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    ContentView()
}

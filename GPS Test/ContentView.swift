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
            .padding(.bottom, 20)
            
            // GPS Data Display
            VStack(spacing: 30) {
                // Latitude
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latitude")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(String(format: coordinateFormat, bleManager.latitude))
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Longitude
                VStack(alignment: .leading, spacing: 8) {
                    Text("Longitude")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(String(format: coordinateFormat, bleManager.longitude))
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 20) {
                if !bleManager.isConnected {
                    Button(action: {
                        bleManager.startScanning()
                    }) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text(bleManager.isScanning ? "Scanning..." : "Connect")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bleManager.isScanning ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

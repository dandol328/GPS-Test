//
//  MinMaxView.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import SwiftUI

class MinMaxTracker: ObservableObject {
    @Published var maxSpeed: Double = 0.0
    @Published var maxAltitude: Double = -Double.infinity
    @Published var minAltitude: Double = Double.infinity
    @Published var maxGForceX: Double = 0.0
    @Published var minGForceX: Double = 0.0
    @Published var maxGForceY: Double = 0.0
    @Published var minGForceY: Double = 0.0
    @Published var maxGForceZ: Double = 0.0
    @Published var minGForceZ: Double = 0.0
    @Published var maxAcceleration: Double = 0.0  // Combined G-force magnitude
    @Published var maxDeceleration: Double = 0.0
    
    @Published var sessions: [MinMaxSession] = []
    
    func update(speed: Double, altitude: Double, gx: Double, gy: Double, gz: Double) {
        maxSpeed = max(maxSpeed, speed)
        maxAltitude = max(maxAltitude, altitude)
        minAltitude = min(minAltitude, altitude)
        
        maxGForceX = max(maxGForceX, gx)
        minGForceX = min(minGForceX, gx)
        maxGForceY = max(maxGForceY, gy)
        minGForceY = min(minGForceY, gy)
        maxGForceZ = max(maxGForceZ, gz)
        minGForceZ = min(minGForceZ, gz)
        
        // Calculate combined G-force (forward/backward acceleration)
        let combinedG = sqrt(gx * gx + gy * gy + gz * gz)
        maxAcceleration = max(maxAcceleration, gx)  // Positive X is forward
        maxDeceleration = max(maxDeceleration, -gx)  // Negative X is backward (braking)
    }
    
    func reset() {
        maxSpeed = 0.0
        maxAltitude = -Double.infinity
        minAltitude = Double.infinity
        maxGForceX = 0.0
        minGForceX = 0.0
        maxGForceY = 0.0
        minGForceY = 0.0
        maxGForceZ = 0.0
        minGForceZ = 0.0
        maxAcceleration = 0.0
        maxDeceleration = 0.0
    }
    
    func saveSession() {
        let session = MinMaxSession(
            date: Date(),
            maxSpeed: maxSpeed,
            maxAltitude: maxAltitude,
            minAltitude: minAltitude,
            maxAcceleration: maxAcceleration,
            maxDeceleration: maxDeceleration
        )
        sessions.insert(session, at: 0)
        // Keep only last 10 sessions
        if sessions.count > 10 {
            sessions = Array(sessions.prefix(10))
        }
    }
}

struct MinMaxSession: Identifiable {
    let id = UUID()
    let date: Date
    let maxSpeed: Double
    let maxAltitude: Double
    let minAltitude: Double
    let maxAcceleration: Double
    let maxDeceleration: Double
}

struct MinMaxView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settings: UserSettings
    @StateObject private var tracker = MinMaxTracker()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Session
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current Session")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        // Speed
                        MinMaxCard(
                            title: "Max Speed",
                            value: settings.convertSpeed(tracker.maxSpeed),
                            unit: settings.speedUnitLabel(),
                            icon: "speedometer",
                            color: .blue
                        )
                        
                        // Altitude
                        HStack(spacing: 12) {
                            MinMaxCard(
                                title: "Max Alt",
                                value: settings.convertAltitude(tracker.maxAltitude == -Double.infinity ? 0 : tracker.maxAltitude),
                                unit: settings.altitudeUnitLabel(),
                                icon: "arrow.up",
                                color: .green
                            )
                            
                            MinMaxCard(
                                title: "Min Alt",
                                value: settings.convertAltitude(tracker.minAltitude == Double.infinity ? 0 : tracker.minAltitude),
                                unit: settings.altitudeUnitLabel(),
                                icon: "arrow.down",
                                color: .orange
                            )
                        }
                        
                        // G-Forces
                        HStack(spacing: 12) {
                            MinMaxCard(
                                title: "Max Accel",
                                value: tracker.maxAcceleration,
                                unit: "g",
                                icon: "arrow.right",
                                color: .red
                            )
                            
                            MinMaxCard(
                                title: "Max Decel",
                                value: tracker.maxDeceleration,
                                unit: "g",
                                icon: "arrow.left",
                                color: .purple
                            )
                        }
                        
                        // G-Force Details
                        VStack(spacing: 8) {
                            MinMaxRowCard(title: "G-Force X", min: tracker.minGForceX, max: tracker.maxGForceX)
                            MinMaxRowCard(title: "G-Force Y", min: tracker.minGForceY, max: tracker.maxGForceY)
                            MinMaxRowCard(title: "G-Force Z", min: tracker.minGForceZ, max: tracker.maxGForceZ)
                        }
                    }
                    .padding()
                    
                    // Control Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            tracker.saveSession()
                        }) {
                            Label("Save Session", systemImage: "tray.and.arrow.down")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            tracker.reset()
                        }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Saved Sessions
                    if !tracker.sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Saved Sessions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(tracker.sessions) { session in
                                SessionCard(session: session, settings: settings)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Min / Max")
            .onChange(of: bleManager.speed) { _ in
                let calibratedG = settings.applyGForceCalibration(
                    x: bleManager.accelerometerX,
                    y: bleManager.accelerometerY,
                    z: bleManager.accelerometerZ
                )
                tracker.update(
                    speed: bleManager.speed,
                    altitude: bleManager.altitude,
                    gx: calibratedG.x,
                    gy: calibratedG.y,
                    gz: calibratedG.z
                )
            }
        }
    }
}

struct MinMaxCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct MinMaxRowCard: View {
    let title: String
    let min: Double
    let max: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 16) {
                VStack(alignment: .trailing) {
                    Text("Min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f g", min))
                        .font(.system(.body, design: .monospaced))
                }
                VStack(alignment: .trailing) {
                    Text("Max")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f g", max))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct SessionCard: View {
    let session: MinMaxSession
    let settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(session.date, style: .date)
                    .font(.headline)
                Text(session.date, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Max Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@", settings.convertSpeed(session.maxSpeed), settings.speedUnitLabel()))
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Max Accel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f g", session.maxAcceleration))
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Max Decel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f g", session.maxDeceleration))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MinMaxView(bleManager: BLEManager(), settings: UserSettings())
}

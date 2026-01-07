//
//  PerformanceTimingView.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import SwiftUI

class PerformanceTimer: ObservableObject {
    @Published var isRunning = false
    @Published var currentSpeed: Double = 0.0
    @Published var currentDistance: Double = 0.0  // meters
    
    // 0-60 timing (mph or kph based on settings)
    @Published var time0to60: Double? = nil
    @Published var best0to60: Double? = nil
    
    // 1/8 mile timing
    @Published var time8thMile: Double? = nil
    @Published var speed8thMile: Double? = nil
    @Published var best8thMile: Double? = nil
    
    // 1/4 mile timing
    @Published var timeQuarterMile: Double? = nil
    @Published var speedQuarterMile: Double? = nil
    @Published var bestQuarterMile: Double? = nil
    
    private var startTime: Date?
    private var lastUpdateTime: Date?
    private var lastSpeed: Double = 0.0
    private let eighthMileMeters = 201.168  // 1/8 mile in meters
    private let quarterMileMeters = 402.336  // 1/4 mile in meters
    
    func start() {
        reset()
        isRunning = true
        startTime = Date()
        lastUpdateTime = Date()
    }
    
    func stop() {
        isRunning = false
        
        // Update best times
        if let time = time0to60 {
            if best0to60 == nil || time < best0to60! {
                best0to60 = time
            }
        }
        
        if let time = time8thMile {
            if best8thMile == nil || time < best8thMile! {
                best8thMile = time
            }
        }
        
        if let time = timeQuarterMile {
            if bestQuarterMile == nil || time < bestQuarterMile! {
                bestQuarterMile = time
            }
        }
    }
    
    func reset() {
        time0to60 = nil
        time8thMile = nil
        speed8thMile = nil
        timeQuarterMile = nil
        speedQuarterMile = nil
        currentDistance = 0.0
        startTime = nil
        lastUpdateTime = nil
        lastSpeed = 0.0
    }
    
    func update(speed: Double, speedUnit: SpeedUnit) {
        guard isRunning, let start = startTime else { return }
        
        currentSpeed = speed
        let now = Date()
        let elapsed = now.timeIntervalSince(start)
        
        // Calculate distance traveled using trapezoidal integration
        if let lastTime = lastUpdateTime {
            let dt = now.timeIntervalSince(lastTime)
            let avgSpeed = (speed + lastSpeed) / 2.0  // Average speed in m/s
            currentDistance += avgSpeed * dt
        }
        
        lastUpdateTime = now
        lastSpeed = speed
        
        // Check 0-60 (mph or kph depending on unit)
        if time0to60 == nil {
            let targetSpeed: Double
            // Use 60 for mph and kph, equivalent values for other units
            if speedUnit == .milesPerHour {
                targetSpeed = 60.0  // 60 mph
            } else if speedUnit == .kilometersPerHour {
                targetSpeed = 60.0  // 60 kph (common benchmark)
            } else if speedUnit == .metersPerSecond {
                targetSpeed = 16.6667  // ~60 kph in m/s
            } else {  // knots
                targetSpeed = 32.4  // ~60 kph in knots
            }
            let convertedSpeed = speedUnit.convert(speed)
            
            if convertedSpeed >= targetSpeed {
                time0to60 = elapsed
            }
        }
        
        // Check 1/8 mile
        if time8thMile == nil && currentDistance >= eighthMileMeters {
            time8thMile = elapsed
            speed8thMile = speedUnit.convert(speed)
        }
        
        // Check 1/4 mile
        if timeQuarterMile == nil && currentDistance >= quarterMileMeters {
            timeQuarterMile = elapsed
            speedQuarterMile = speedUnit.convert(speed)
        }
        
        // Auto-stop after 1/4 mile
        if currentDistance >= quarterMileMeters && timeQuarterMile != nil {
            stop()
        }
    }
    
    func resetBestTimes() {
        best0to60 = nil
        best8thMile = nil
        bestQuarterMile = nil
    }
}

struct PerformanceTimingView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settings: UserSettings
    @StateObject private var timer = PerformanceTimer()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status
                    VStack(spacing: 12) {
                        Text(timer.isRunning ? "Running..." : "Ready")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(timer.isRunning ? .green : .secondary)
                            .animation(.easeInOut(duration: 0.3), value: timer.isRunning)
                        
                        if timer.isRunning {
                            HStack(spacing: 20) {
                                VStack {
                                    Text("Speed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", settings.convertSpeed(timer.currentSpeed)))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    Text(settings.speedUnitLabel())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.0f", timer.currentDistance))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    Text("m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    
                    // Results
                    VStack(spacing: 16) {
                        Text("Current Run")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        PerformanceResultCard(
                            title: settings.speedUnit == .milesPerHour ? "0-60 mph" : 
                                   settings.speedUnit == .kilometersPerHour ? "0-60 kph" :
                                   settings.speedUnit == .knots ? "0-32 knots" : "0-60 kph",
                            time: timer.time0to60,
                            speed: nil,
                            bestTime: timer.best0to60,
                            icon: "gauge.high",
                            color: .blue
                        )
                        
                        PerformanceResultCard(
                            title: "1/8 Mile",
                            time: timer.time8thMile,
                            speed: timer.speed8thMile,
                            bestTime: timer.best8thMile,
                            icon: "flag.checkered",
                            color: .orange,
                            speedUnit: settings.speedUnitLabel()
                        )
                        
                        PerformanceResultCard(
                            title: "1/4 Mile",
                            time: timer.timeQuarterMile,
                            speed: timer.speedQuarterMile,
                            bestTime: timer.bestQuarterMile,
                            icon: "flag.checkered.2.crossed",
                            color: .red,
                            speedUnit: settings.speedUnitLabel()
                        )
                    }
                    .padding(.horizontal)
                    
                    // Control Buttons
                    VStack(spacing: 12) {
                        if !timer.isRunning {
                            Button(action: {
                                timer.start()
                            }) {
                                Label("Start", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(!bleManager.isConnected)
                        } else {
                            Button(action: {
                                timer.stop()
                            }) {
                                Label("Stop", systemImage: "stop.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                timer.reset()
                            }) {
                                Label("Reset Run", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                timer.resetBestTimes()
                            }) {
                                Label("Reset Bests", systemImage: "trash")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    
                    if !bleManager.isConnected {
                        Text("Connect to RaceBox to start timing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Performance")
            .onChange(of: bleManager.speed) { _ in
                timer.update(speed: bleManager.speed, speedUnit: settings.speedUnit)
            }
        }
    }
}

struct PerformanceResultCard: View {
    let title: String
    let time: Double?
    let speed: Double?
    let bestTime: Double?
    let icon: String
    let color: Color
    var speedUnit: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let time = time {
                        Text(String(format: "%.3f s", time))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    } else {
                        Text("--")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                if speed != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let spd = speed {
                            Text(String(format: "%.1f %@", spd, speedUnit))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        } else {
                            Text("--")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if let best = bestTime {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Best")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                        Text(String(format: "%.3f s", best))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

#Preview {
    PerformanceTimingView(bleManager: BLEManager(), settings: UserSettings())
}

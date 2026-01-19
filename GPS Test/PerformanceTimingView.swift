//
//  PerformanceTimingView.swift
//  GPS Test
//
//  Created by Dan on 1/7/26.
//

import SwiftUI

struct PerformanceTimingView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settings: UserSettings
    @ObservedObject var sessionManager: SessionManager
    @State private var currentMetrics: MetricsSummary?
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status
                    VStack(spacing: 12) {
                        Text(sessionManager.isRecording ? "Recording..." : "Ready")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(sessionManager.isRecording ? .green : .secondary)
                            .animation(.easeInOut(duration: 0.3), value: sessionManager.isRecording)
                        
                        if sessionManager.isRecording {
                            HStack(spacing: 20) {
                                VStack {
                                    Text("Speed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", settings.convertSpeed(bleManager.speed)))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    Text(settings.speedUnitLabel())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.0f", sessionManager.currentSession?.totalDistance ?? 0))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    Text("m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("Samples")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(sessionManager.currentSession?.samples.count ?? 0)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    Text("points")
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
                    
                    // Results - show when available
                    if let metrics = currentMetrics, !metrics.results.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Performance Results")
                                    .font(.headline)
                                Spacer()
                                Button("Clear") {
                                    currentMetrics = nil
                                    showingResults = false
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            
                            ForEach(metrics.results.sorted(by: { $0.metricType.displayOrder < $1.metricType.displayOrder })) { result in
                                PerformanceMetricCard(result: result, settings: settings)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Control Buttons
                    VStack(spacing: 12) {
                        if !sessionManager.isRecording {
                            Button(action: {
                                sessionManager.startRecording(sampleRateHz: settings.sampleRateHz)
                                currentMetrics = nil
                                showingResults = false
                            }) {
                                Label("Start Recording", systemImage: "play.fill")
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
                                if let session = sessionManager.stopRecording() {
                                    // Compute metrics immediately after stopping
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let engine = MetricsEngine()
                                        let summary = engine.computeMetrics(session: session, accuracyThreshold: settings.accuracyThreshold)
                                        DispatchQueue.main.async {
                                            currentMetrics = summary
                                            showingResults = true
                                        }
                                    }
                                }
                            }) {
                                Label("Stop Recording", systemImage: "stop.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    
                    if !bleManager.isConnected {
                        Text("Connect to RaceBox to start recording")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    
                    if sessionManager.isRecording {
                        Text("Recording will save to Sessions tab when stopped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Performance")
        }
    }
}

struct PerformanceMetricCard: View {
    let result: MetricResult
    @ObservedObject var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.metricType.displayName)
                    .font(.headline)
                Spacer()
                if !result.isReliable {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("Low Accuracy")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f s", result.elapsedTime))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                
                if result.metricType.isDistanceBased {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trap Speed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let trapSpeed = result.trapSpeed {
                            Text(String(format: "%.1f %@", settings.convertSpeed(trapSpeed), settings.speedUnitLabel()))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        } else {
                            Text("--")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
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
    PerformanceTimingView(bleManager: BLEManager(), settings: UserSettings(), sessionManager: SessionManager())
}

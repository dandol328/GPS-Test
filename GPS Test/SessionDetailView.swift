//
//  SessionDetailView.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import SwiftUI

struct SessionDetailView: View {
    let session: RecordingSession
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var settings: UserSettings
    
    @State private var metrics: MetricsSummary?
    @State private var isComputingMetrics = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Info
                VStack(spacing: 12) {
                    SectionHeader(title: "Session Info", icon: "info.circle")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Start Time", value: dateFormatter.string(from: session.startTime))
                        if let endTime = session.endTime {
                            InfoRow(label: "End Time", value: dateFormatter.string(from: endTime))
                        }
                        InfoRow(label: "Duration", value: String(format: "%.1f seconds", session.duration))
                        InfoRow(label: "Sample Count", value: "\(session.samples.count)")
                        InfoRow(label: "Sample Rate", value: "\(session.sampleRateHz) Hz")
                        InfoRow(label: "Distance", value: String(format: "%.2f meters", session.totalDistance))
                        InfoRow(label: "Max Speed", value: String(format: "%.2f %@", settings.convertSpeed(session.maxSpeed), settings.speedUnitLabel()))
                        InfoRow(label: "Avg Speed", value: String(format: "%.2f %@", settings.convertSpeed(session.avgSpeed), settings.speedUnitLabel()))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Metrics Section
                VStack(spacing: 12) {
                    HStack {
                        SectionHeader(title: "Performance Metrics", icon: "gauge")
                        Spacer()
                        if metrics == nil && !isComputingMetrics {
                            Button("Compute") {
                                computeMetrics()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if isComputingMetrics {
                        ProgressView("Computing metrics...")
                            .padding()
                    } else if let summary = metrics {
                        if summary.results.isEmpty {
                            Text("No metrics available. The session may not contain a valid performance run.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(summary.results.sorted(by: { $0.metricType.displayOrder < $1.metricType.displayOrder })) { result in
                                    MetricCard(result: result, settings: settings)
                                }
                            }
                        }
                    } else {
                        Text("Tap 'Compute' to calculate performance metrics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                // Export Section
                VStack(spacing: 12) {
                    SectionHeader(title: "Export", icon: "square.and.arrow.up")
                    
                    VStack(spacing: 10) {
                        ExportButton(title: "Export as JSON", icon: "doc.text", color: .blue) {
                            exportToFormat("json")
                        }
                        
                        ExportButton(title: "Export as CSV", icon: "tablecells", color: .green) {
                            exportToFormat("csv")
                        }
                        
                        ExportButton(title: "Export as GPX", icon: "map", color: .orange) {
                            exportToFormat("gpx")
                        }
                        
                        ExportButton(title: "Export as KML", icon: "globe", color: .red) {
                            exportToFormat("kml")
                        }
                        
                        ExportButton(title: "Export All Formats", icon: "square.stack.3d.up.fill", color: .purple) {
                            exportAllFormats()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if !shareItems.isEmpty {
                ActivityViewController(activityItems: shareItems)
            }
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    private func computeMetrics() {
        isComputingMetrics = true
        DispatchQueue.global(qos: .userInitiated).async {
            let engine = MetricsEngine()
            let summary = engine.computeMetrics(session: session, accuracyThreshold: settings.accuracyThreshold)
            DispatchQueue.main.async {
                self.metrics = summary
                self.isComputingMetrics = false
            }
        }
    }
    
    private func exportToFormat(_ format: String) {
        guard !session.samples.isEmpty else {
            exportErrorMessage = "Session contains no samples to export."
            showingExportError = true
            return
        }
        
        let data: Data?
        switch format {
        case "json":
            data = SessionExporter.exportToJSON(session: session, metrics: metrics)
        case "csv":
            data = SessionExporter.exportToCSV(session: session, metrics: metrics)
        case "gpx":
            data = SessionExporter.exportToGPX(session: session)
        case "kml":
            data = SessionExporter.exportToKML(session: session)
        default:
            return
        }
        
        guard let exportData = data else {
            exportErrorMessage = "Failed to generate \(format.uppercased()) export data."
            showingExportError = true
            return
        }
        
        let filename = SessionExporter.suggestedFilename(for: session, format: format)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try exportData.write(to: tempURL)
            shareItems = [tempURL]
            showingShareSheet = true
        } catch {
            exportErrorMessage = "Failed to save export file: \(error.localizedDescription)"
            showingExportError = true
        }
    }
    
    private func exportAllFormats() {
        guard !session.samples.isEmpty else {
            exportErrorMessage = "Session contains no samples to export."
            showingExportError = true
            return
        }
        
        let exports = SessionExporter.exportToAllFormats(session: session, metrics: metrics)
        var urls: [URL] = []
        var failedFormats: [String] = []
        
        for (format, data) in exports {
            let filename = SessionExporter.suggestedFilename(for: session, format: format)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try data.write(to: tempURL)
                urls.append(tempURL)
            } catch {
                failedFormats.append(format.uppercased())
            }
        }
        
        if !urls.isEmpty {
            shareItems = urls
            showingShareSheet = true
            
            if !failedFormats.isEmpty {
                exportErrorMessage = "Some exports failed: \(failedFormats.joined(separator: ", "))"
                showingExportError = true
            }
        } else {
            exportErrorMessage = "All exports failed. Please try individual formats."
            showingExportError = true
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct MetricCard: View {
    let result: MetricResult
    @ObservedObject var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Time:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.3f s", result.elapsedTime))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                if result.metricType.isDistanceBased, let trap = result.trapSpeed {
                    HStack {
                        Text("Trap Speed:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f %@", settings.convertSpeed(trap), settings.speedUnitLabel()))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                
                if let peak = result.peakSpeed {
                    HStack {
                        Text("Peak Speed:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f %@", settings.convertSpeed(peak), settings.speedUnitLabel()))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                
                HStack {
                    Text("Distance:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f m", result.distance))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Accuracy:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "±%.1f m", result.avgHorizontalAccuracy))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
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

struct ExportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(color)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// Activity View Controller for sharing
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        SessionDetailView(
            session: RecordingSession(),
            sessionManager: SessionManager(),
            settings: UserSettings()
        )
    }
}

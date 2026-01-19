//
//  CSVExporter.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Exports session data to CSV format
struct CSVExporter {
    
    /// Export session to CSV format with metrics summary and sample data
    /// - Parameters:
    ///   - session: Recording session to export
    ///   - metrics: Optional metrics summary
    /// - Returns: CSV data or nil on error
    static func export(session: RecordingSession, metrics: MetricsSummary? = nil) -> Data? {
        var csv = ""
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Session metadata header
        csv += "# GPS Test Session Export\n"
        csv += "# Session ID: \(session.id.uuidString)\n"
        csv += "# Start Time: \(iso8601Formatter.string(from: session.startTime))\n"
        if let endTime = session.endTime {
            csv += "# End Time: \(iso8601Formatter.string(from: endTime))\n"
        }
        csv += "# Sample Rate: \(session.sampleRateHz) Hz\n"
        if let name = session.name {
            csv += "# Name: \(name)\n"
        }
        if let tags = session.tags, !tags.isEmpty {
            csv += "# Tags: \(tags.joined(separator: ", "))\n"
        }
        if let notes = session.notes {
            csv += "# Notes: \(notes)\n"
        }
        csv += "#\n"
        
        // Metrics summary section
        if let metrics = metrics, !metrics.results.isEmpty {
            csv += "# METRICS SUMMARY\n"
            csv += "# Computed At: \(iso8601Formatter.string(from: metrics.computedAt))\n"
            csv += "# Accuracy Threshold: \(metrics.accuracyThreshold)m\n"
            csv += "# Filtered Data: \(metrics.useFilteredData)\n"
            csv += "#\n"
            csv += "# Metric,Elapsed Time (s),Trap Speed (m/s),Peak Speed (m/s),Distance (m),Avg Accuracy (m),Samples,Reliable\n"
            
            for result in metrics.results {
                let trapSpeed = result.trapSpeed.map { String(format: "%.2f", $0) } ?? ""
                let peakSpeed = result.peakSpeed.map { String(format: "%.2f", $0) } ?? ""
                csv += "# \(result.metricType.rawValue),"
                csv += "\(String(format: "%.4f", result.elapsedTime)),"
                csv += "\(trapSpeed),"
                csv += "\(peakSpeed),"
                csv += "\(String(format: "%.2f", result.distance)),"
                csv += "\(String(format: "%.2f", result.avgHorizontalAccuracy)),"
                csv += "\(result.sampleCount),"
                csv += "\(result.isReliable)\n"
            }
            csv += "#\n"
        }
        
        // Sample data header
        csv += "timestamp,latitude,longitude,altitude,speed,heading,horizontalAccuracy,verticalAccuracy,speedAccuracy,fixType,satellites,pdop,hdop,vdop\n"
        
        // Sample data rows
        for sample in session.samples {
            csv += "\(iso8601Formatter.string(from: sample.timestamp)),"
            csv += "\(sample.latitude),"
            csv += "\(sample.longitude),"
            csv += "\(sample.altitude.map { String($0) } ?? ""),"
            csv += "\(sample.speed),"
            csv += "\(sample.heading.map { String($0) } ?? ""),"
            csv += "\(sample.horizontalAccuracy),"
            csv += "\(sample.verticalAccuracy.map { String($0) } ?? ""),"
            csv += "\(sample.speedAccuracy.map { String($0) } ?? ""),"
            csv += "\(sample.fixType.rawValue),"
            csv += "\(sample.satellites.map { String($0) } ?? ""),"
            csv += "\(sample.pdop.map { String($0) } ?? ""),"
            csv += "\(sample.hdop.map { String($0) } ?? ""),"
            csv += "\(sample.vdop.map { String($0) } ?? "")\n"
        }
        
        return csv.data(using: .utf8)
    }
}

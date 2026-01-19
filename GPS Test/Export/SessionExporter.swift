//
//  SessionExporter.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Main export class for GPS recording sessions
/// Provides export functionality to JSON, CSV, GPX, and KML formats
class SessionExporter {
    
    /// Export errors
    enum ExportError: Error, LocalizedError {
        case encodingFailed
        case noSamples
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode export data"
            case .noSamples:
                return "Session contains no samples to export"
            case .invalidData:
                return "Invalid session data"
            }
        }
    }
    
    // MARK: - JSON Export
    
    /// Export session to JSON format
    /// - Parameters:
    ///   - session: Recording session to export
    ///   - metrics: Optional metrics summary to include
    /// - Returns: JSON data or nil on error
    static func exportToJSON(session: RecordingSession, metrics: MetricsSummary? = nil) -> Data? {
        guard !session.samples.isEmpty else {
            return nil
        }
        
        let exportFormat = JSONExportFormat.from(session: session, metrics: metrics)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        do {
            return try encoder.encode(exportFormat)
        } catch {
            print("JSON export error: \(error)")
            return nil
        }
    }
    
    // MARK: - CSV Export
    
    /// Export session to CSV format
    /// - Parameters:
    ///   - session: Recording session to export
    ///   - metrics: Optional metrics summary to include
    /// - Returns: CSV data or nil on error
    static func exportToCSV(session: RecordingSession, metrics: MetricsSummary? = nil) -> Data? {
        guard !session.samples.isEmpty else {
            return nil
        }
        
        return CSVExporter.export(session: session, metrics: metrics)
    }
    
    // MARK: - GPX Export
    
    /// Export session to GPX 1.1 format
    /// - Parameter session: Recording session to export
    /// - Returns: GPX XML data or nil on error
    static func exportToGPX(session: RecordingSession) -> Data? {
        guard !session.samples.isEmpty else {
            return nil
        }
        
        return GPXExporter.export(session: session)
    }
    
    // MARK: - KML Export
    
    /// Export session to KML format
    /// - Parameter session: Recording session to export
    /// - Returns: KML XML data or nil on error
    static func exportToKML(session: RecordingSession) -> Data? {
        guard !session.samples.isEmpty else {
            return nil
        }
        
        return KMLExporter.export(session: session)
    }
    
    // MARK: - Convenience Methods
    
    /// Get filename for export based on session and format
    /// - Parameters:
    ///   - session: Recording session
    ///   - format: Export format extension (json, csv, gpx, kml)
    /// - Returns: Suggested filename
    static func suggestedFilename(for session: RecordingSession, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: session.startTime)
        
        if let name = session.name, !name.isEmpty {
            let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
            let sanitized = name.unicodeScalars
                .map { allowedCharacters.contains($0) ? String($0) : "_" }
                .joined()
            return "\(sanitized)_\(timestamp).\(format)"
        } else {
            return "gps_session_\(timestamp).\(format)"
        }
    }
    
    /// Export session to all formats
    /// - Parameters:
    ///   - session: Recording session to export
    ///   - metrics: Optional metrics summary
    /// - Returns: Dictionary of format to data mappings
    static func exportToAllFormats(
        session: RecordingSession,
        metrics: MetricsSummary? = nil
    ) -> [String: Data] {
        var exports: [String: Data] = [:]
        
        if let jsonData = exportToJSON(session: session, metrics: metrics) {
            exports["json"] = jsonData
        }
        
        if let csvData = exportToCSV(session: session, metrics: metrics) {
            exports["csv"] = csvData
        }
        
        if let gpxData = exportToGPX(session: session) {
            exports["gpx"] = gpxData
        }
        
        if let kmlData = exportToKML(session: session) {
            exports["kml"] = kmlData
        }
        
        return exports
    }
}

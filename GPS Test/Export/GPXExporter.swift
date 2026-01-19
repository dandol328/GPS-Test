//
//  GPXExporter.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Exports session data to GPX 1.1 format
struct GPXExporter {
    
    /// Export session to GPX 1.1 format
    /// - Parameter session: Recording session to export
    /// - Returns: GPX XML data or nil on error
    static func export(session: RecordingSession) -> Data? {
        var gpx = ""
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // XML declaration and GPX root
        gpx += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpx += "<gpx version=\"1.1\" creator=\"GPS Test\" "
        gpx += "xmlns=\"http://www.topografix.com/GPX/1/1\" "
        gpx += "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
        gpx += "xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n"
        
        // Metadata
        gpx += "  <metadata>\n"
        gpx += "    <time>\(iso8601Formatter.string(from: session.startTime))</time>\n"
        if let name = session.name {
            gpx += "    <name>\(escapeXML(name))</name>\n"
        }
        if let notes = session.notes {
            gpx += "    <desc>\(escapeXML(notes))</desc>\n"
        }
        gpx += "  </metadata>\n"
        
        // Track
        gpx += "  <trk>\n"
        gpx += "    <name>\(escapeXML(session.name ?? "GPS Track"))</name>\n"
        gpx += "    <type>GPS Test Recording</type>\n"
        
        // Track segment
        gpx += "    <trkseg>\n"
        
        for sample in session.samples {
            gpx += "      <trkpt lat=\"\(String(format: "%.8f", sample.latitude))\" "
            gpx += "lon=\"\(String(format: "%.8f", sample.longitude))\">\n"
            
            if let altitude = sample.altitude {
                gpx += "        <ele>\(String(format: "%.2f", altitude))</ele>\n"
            }
            
            gpx += "        <time>\(iso8601Formatter.string(from: sample.timestamp))</time>\n"
            
            // GPX 1.1 extensions for additional data
            gpx += "        <extensions>\n"
            gpx += "          <speed>\(String(format: "%.3f", sample.speed))</speed>\n"
            
            if let heading = sample.heading {
                gpx += "          <course>\(String(format: "%.2f", heading))</course>\n"
            }
            
            if let hdop = sample.hdop {
                gpx += "          <hdop>\(String(format: "%.2f", hdop))</hdop>\n"
            }
            
            if let vdop = sample.vdop {
                gpx += "          <vdop>\(String(format: "%.2f", vdop))</vdop>\n"
            }
            
            if let pdop = sample.pdop {
                gpx += "          <pdop>\(String(format: "%.2f", pdop))</pdop>\n"
            }
            
            if let satellites = sample.satellites {
                gpx += "          <sat>\(satellites)</sat>\n"
            }
            
            gpx += "          <fix>\(sample.fixType.rawValue)</fix>\n"
            gpx += "          <hacc>\(String(format: "%.2f", sample.horizontalAccuracy))</hacc>\n"
            
            if let verticalAccuracy = sample.verticalAccuracy {
                gpx += "          <vacc>\(String(format: "%.2f", verticalAccuracy))</vacc>\n"
            }
            
            if let speedAccuracy = sample.speedAccuracy {
                gpx += "          <sacc>\(String(format: "%.3f", speedAccuracy))</sacc>\n"
            }
            
            gpx += "        </extensions>\n"
            gpx += "      </trkpt>\n"
        }
        
        gpx += "    </trkseg>\n"
        gpx += "  </trk>\n"
        gpx += "</gpx>\n"
        
        return gpx.data(using: .utf8)
    }
    
    /// Escape special XML characters
    private static func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

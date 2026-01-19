//
//  KMLExporter.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Exports session data to KML format
struct KMLExporter {
    
    // KML color constants (KML uses AABBGGRR format)
    private static let trackLineColor = "ff0000ff"  // Red
    private static let startPointColor = "ff00ff00"  // Green
    private static let endPointColor = "ff0000ff"  // Red
    private static let trackLineWidth = "3"
    private static let pointIconScale = "1.2"
    
    /// Export session to KML format with track and placemarks
    /// - Parameter session: Recording session to export
    /// - Returns: KML XML data or nil on error
    static func export(session: RecordingSession) -> Data? {
        var kml = ""
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // XML declaration and KML root
        kml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        kml += "<kml xmlns=\"http://www.opengis.net/kml/2.2\" "
        kml += "xmlns:gx=\"http://www.google.com/kml/ext/2.2\">\n"
        kml += "  <Document>\n"
        
        // Document name and description
        kml += "    <name>\(escapeXML(session.name ?? "GPS Test Session"))</name>\n"
        kml += "    <description>\(escapeXML(makeDescription(session)))</description>\n"
        
        // Define styles
        kml += defineStyles()
        
        // Track as LineString
        if !session.samples.isEmpty {
            kml += "    <Placemark>\n"
            kml += "      <name>GPS Track</name>\n"
            kml += "      <styleUrl>#trackStyle</styleUrl>\n"
            kml += "      <gx:Track>\n"
            
            // When elements (timestamps)
            for sample in session.samples {
                kml += "        <when>\(iso8601Formatter.string(from: sample.timestamp))</when>\n"
            }
            
            // Coordinates (lon, lat, alt)
            for sample in session.samples {
                let alt = sample.altitude ?? 0.0
                kml += "        <gx:coord>\(String(format: "%.8f", sample.longitude)) "
                kml += "\(String(format: "%.8f", sample.latitude)) "
                kml += "\(String(format: "%.2f", alt))</gx:coord>\n"
            }
            
            // Extended data for each point
            for sample in session.samples {
                kml += "        <ExtendedData>\n"
                kml += "          <Data name=\"speed\">\n"
                kml += "            <value>\(String(format: "%.3f", sample.speed))</value>\n"
                kml += "          </Data>\n"
                
                if let heading = sample.heading {
                    kml += "          <Data name=\"heading\">\n"
                    kml += "            <value>\(String(format: "%.2f", heading))</value>\n"
                    kml += "          </Data>\n"
                }
                
                if let satellites = sample.satellites {
                    kml += "          <Data name=\"satellites\">\n"
                    kml += "            <value>\(satellites)</value>\n"
                    kml += "          </Data>\n"
                }
                
                if let pdop = sample.pdop {
                    kml += "          <Data name=\"pdop\">\n"
                    kml += "            <value>\(String(format: "%.2f", pdop))</value>\n"
                    kml += "          </Data>\n"
                }
                
                kml += "          <Data name=\"fixType\">\n"
                kml += "            <value>\(sample.fixType.rawValue)</value>\n"
                kml += "          </Data>\n"
                kml += "        </ExtendedData>\n"
            }
            
            kml += "      </gx:Track>\n"
            kml += "    </Placemark>\n"
        }
        
        // Start and end point placemarks
        if let firstSample = session.samples.first {
            kml += createPlacemark(
                name: "Start",
                description: "Session start point",
                sample: firstSample,
                styleUrl: "#startStyle"
            )
        }
        
        if let lastSample = session.samples.last, session.samples.count > 1 {
            kml += createPlacemark(
                name: "End",
                description: "Session end point",
                sample: lastSample,
                styleUrl: "#endStyle"
            )
        }
        
        kml += "  </Document>\n"
        kml += "</kml>\n"
        
        return kml.data(using: .utf8)
    }
    
    /// Create KML styles
    private static func defineStyles() -> String {
        var styles = ""
        
        // Track line style
        styles += "    <Style id=\"trackStyle\">\n"
        styles += "      <LineStyle>\n"
        styles += "        <color>\(trackLineColor)</color>\n"
        styles += "        <width>\(trackLineWidth)</width>\n"
        styles += "      </LineStyle>\n"
        styles += "    </Style>\n"
        
        // Start point style
        styles += "    <Style id=\"startStyle\">\n"
        styles += "      <IconStyle>\n"
        styles += "        <color>\(startPointColor)</color>\n"
        styles += "        <scale>\(pointIconScale)</scale>\n"
        styles += "      </IconStyle>\n"
        styles += "    </Style>\n"
        
        // End point style
        styles += "    <Style id=\"endStyle\">\n"
        styles += "      <IconStyle>\n"
        styles += "        <color>\(endPointColor)</color>\n"
        styles += "        <scale>\(pointIconScale)</scale>\n"
        styles += "      </IconStyle>\n"
        styles += "    </Style>\n"
        
        return styles
    }
    
    /// Create a placemark for a location sample
    private static func createPlacemark(
        name: String,
        description: String,
        sample: LocationSample,
        styleUrl: String
    ) -> String {
        var placemark = ""
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        placemark += "    <Placemark>\n"
        placemark += "      <name>\(escapeXML(name))</name>\n"
        placemark += "      <description>\(escapeXML(description))</description>\n"
        placemark += "      <styleUrl>\(styleUrl)</styleUrl>\n"
        placemark += "      <TimeStamp>\n"
        placemark += "        <when>\(iso8601Formatter.string(from: sample.timestamp))</when>\n"
        placemark += "      </TimeStamp>\n"
        placemark += "      <Point>\n"
        
        let alt = sample.altitude ?? 0.0
        placemark += "        <coordinates>\(String(format: "%.8f", sample.longitude)),"
        placemark += "\(String(format: "%.8f", sample.latitude)),"
        placemark += "\(String(format: "%.2f", alt))</coordinates>\n"
        
        placemark += "      </Point>\n"
        
        // Extended data
        placemark += "      <ExtendedData>\n"
        placemark += "        <Data name=\"speed\"><value>\(String(format: "%.3f", sample.speed))</value></Data>\n"
        
        if let heading = sample.heading {
            placemark += "        <Data name=\"heading\"><value>\(String(format: "%.2f", heading))</value></Data>\n"
        }
        
        if let satellites = sample.satellites {
            placemark += "        <Data name=\"satellites\"><value>\(satellites)</value></Data>\n"
        }
        
        placemark += "        <Data name=\"fixType\"><value>\(sample.fixType.rawValue)</value></Data>\n"
        placemark += "      </ExtendedData>\n"
        placemark += "    </Placemark>\n"
        
        return placemark
    }
    
    /// Create description for the document
    private static func makeDescription(_ session: RecordingSession) -> String {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        var desc = "GPS Test Recording Session\n"
        desc += "Start: \(iso8601Formatter.string(from: session.startTime))\n"
        if let endTime = session.endTime {
            desc += "End: \(iso8601Formatter.string(from: endTime))\n"
        }
        desc += "Sample Rate: \(session.sampleRateHz) Hz\n"
        desc += "Samples: \(session.samples.count)\n"
        
        if let notes = session.notes {
            desc += "\n\(notes)"
        }
        
        return desc
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

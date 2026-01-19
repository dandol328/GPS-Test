//
//  JSONExportFormat.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// JSON export format structure
struct JSONExportFormat: Codable {
    let session: SessionMetadata
    let samples: [SampleData]
    let metrics: MetricsData?
    
    struct SessionMetadata: Codable {
        let id: String
        let startTime: String
        let endTime: String?
        let sampleRateHz: Int
        let name: String?
        let tags: [String]?
        let notes: String?
    }
    
    struct SampleData: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let timestamp: String
        let horizontalAccuracy: Double
        let verticalAccuracy: Double?
        let speed: Double
        let speedAccuracy: Double?
        let heading: Double?
        let headingAccuracy: Double?
        let fixType: String
        let ageOfFix: Double?
        let satellites: Int?
        let hdop: Double?
        let vdop: Double?
        let pdop: Double?
    }
    
    struct MetricsData: Codable {
        let computedAt: String
        let results: [MetricData]
        
        struct MetricData: Codable {
            let metricType: String
            let elapsedTime: Double
            let trapSpeed: Double?
            let peakSpeed: Double?
            let distance: Double
            let startDistance: Double
            let avgHorizontalAccuracy: Double
            let sampleCount: Int
            let isReliable: Bool
        }
    }
    
    /// Create export format from session and metrics
    static func from(session: RecordingSession, metrics: MetricsSummary?) -> JSONExportFormat {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let sessionMetadata = SessionMetadata(
            id: session.id.uuidString,
            startTime: iso8601Formatter.string(from: session.startTime),
            endTime: session.endTime.map { iso8601Formatter.string(from: $0) },
            sampleRateHz: session.sampleRateHz,
            name: session.name,
            tags: session.tags,
            notes: session.notes
        )
        
        let samples = session.samples.map { sample in
            SampleData(
                latitude: sample.latitude,
                longitude: sample.longitude,
                altitude: sample.altitude,
                timestamp: iso8601Formatter.string(from: sample.timestamp),
                horizontalAccuracy: sample.horizontalAccuracy,
                verticalAccuracy: sample.verticalAccuracy,
                speed: sample.speed,
                speedAccuracy: sample.speedAccuracy,
                heading: sample.heading,
                headingAccuracy: sample.headingAccuracy,
                fixType: sample.fixType.rawValue,
                ageOfFix: sample.ageOfFix,
                satellites: sample.satellites,
                hdop: sample.hdop,
                vdop: sample.vdop,
                pdop: sample.pdop
            )
        }
        
        let metricsData = metrics.map { m in
            MetricsData(
                computedAt: iso8601Formatter.string(from: m.computedAt),
                results: m.results.map { result in
                    MetricsData.MetricData(
                        metricType: result.metricType.rawValue,
                        elapsedTime: result.elapsedTime,
                        trapSpeed: result.trapSpeed,
                        peakSpeed: result.peakSpeed,
                        distance: result.distance,
                        startDistance: result.startDistance,
                        avgHorizontalAccuracy: result.avgHorizontalAccuracy,
                        sampleCount: result.sampleCount,
                        isReliable: result.isReliable
                    )
                }
            )
        }
        
        return JSONExportFormat(
            session: sessionMetadata,
            samples: samples,
            metrics: metricsData
        )
    }
}

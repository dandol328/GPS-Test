//
//  RecordingSession.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// A recording session containing GPS samples and metadata
struct RecordingSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var samples: [LocationSample]
    var name: String?
    var tags: [String]?
    var notes: String?
    
    // Session configuration
    var sampleRateHz: Int  // Configured sample rate (max 25 Hz)
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        samples: [LocationSample] = [],
        name: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil,
        sampleRateHz: Int = 25
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.samples = samples
        self.name = name
        self.tags = tags
        self.notes = notes
        self.sampleRateHz = min(sampleRateHz, 25)  // Cap at 25 Hz
    }
    
    /// Duration of the session in seconds
    var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        } else if let lastSample = samples.last {
            return lastSample.timestamp.timeIntervalSince(startTime)
        }
        return 0
    }
    
    /// Total distance traveled in meters using haversine formula
    var totalDistance: Double {
        guard samples.count >= 2 else { return 0 }
        
        var distance = 0.0
        for i in 1..<samples.count {
            let prev = samples[i - 1]
            let curr = samples[i]
            distance += haversineDistance(
                lat1: prev.latitude,
                lon1: prev.longitude,
                lat2: curr.latitude,
                lon2: curr.longitude
            )
        }
        return distance
    }
    
    /// Maximum speed in m/s across all samples
    var maxSpeed: Double {
        samples.map { $0.speed }.max() ?? 0.0
    }
    
    /// Average speed in m/s across all samples
    var avgSpeed: Double {
        guard !samples.isEmpty else { return 0.0 }
        let total = samples.reduce(0.0) { $0 + $1.speed }
        return total / Double(samples.count)
    }
    
    /// Haversine formula for distance between two lat/lon points
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0  // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

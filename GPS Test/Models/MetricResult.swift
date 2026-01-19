//
//  MetricResult.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Type of performance metric
enum MetricType: String, Codable, CaseIterable {
    // Distance-based
    case sixtyFeet = "60ft"
    case eighthMile = "1/8 mile"
    case quarterMile = "1/4 mile"
    
    // Speed-based (0 to X)
    case zeroToThirty = "0-30"
    case zeroToForty = "0-40"
    case zeroToSixty = "0-60"
    case zeroToEighty = "0-80"
    case zeroToHundred = "0-100"
    
    // Rolling intervals
    case thirtyToSeventy = "30-70"
    case fortyToHundred = "40-100"
    
    // Braking
    case sixtyToZero = "60-0"
    
    var displayName: String {
        rawValue
    }
    
    var isDistanceBased: Bool {
        switch self {
        case .sixtyFeet, .eighthMile, .quarterMile:
            return true
        default:
            return false
        }
    }
    
    var isSpeedBased: Bool {
        switch self {
        case .zeroToThirty, .zeroToForty, .zeroToSixty, .zeroToEighty, .zeroToHundred:
            return true
        default:
            return false
        }
    }
    
    var isRollingInterval: Bool {
        switch self {
        case .thirtyToSeventy, .fortyToHundred:
            return true
        default:
            return false
        }
    }
    
    var isBraking: Bool {
        self == .sixtyToZero
    }
}

/// Result of a performance metric calculation
struct MetricResult: Codable, Identifiable {
    let id: UUID
    let metricType: MetricType
    
    // Timing data
    let elapsedTime: TimeInterval       // seconds (ET)
    let startTimestamp: Date            // when metric started
    let endTimestamp: Date              // when threshold was reached
    
    // Speed data
    let trapSpeed: Double?              // m/s - speed at end of metric
    let peakSpeed: Double?              // m/s - maximum speed during metric
    
    // Distance data
    // NOTE: The interpretation of 'distance' varies by metric type:
    // - Distance-based metrics (60ft, 1/8mi, 1/4mi): cumulative distance from start
    // - Speed-based metrics (0-30, 0-60, etc.): cumulative distance when speed threshold reached
    // - Rolling intervals (30-70, 40-100): cumulative distance at end speed
    // - Braking metrics (60-0): stopping distance (distance traveled during braking)
    let distance: Double                // meters - context-dependent (see note above)
    let startDistance: Double           // meters - distance at metric start
    
    // Quality indicators
    let avgHorizontalAccuracy: Double   // meters - average accuracy during metric
    let sampleCount: Int                // number of samples used
    let isReliable: Bool                // based on accuracy threshold
    
    init(
        id: UUID = UUID(),
        metricType: MetricType,
        elapsedTime: TimeInterval,
        startTimestamp: Date,
        endTimestamp: Date,
        trapSpeed: Double?,
        peakSpeed: Double?,
        distance: Double,
        startDistance: Double = 0.0,
        avgHorizontalAccuracy: Double,
        sampleCount: Int,
        isReliable: Bool
    ) {
        self.id = id
        self.metricType = metricType
        self.elapsedTime = elapsedTime
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.trapSpeed = trapSpeed
        self.peakSpeed = peakSpeed
        self.distance = distance
        self.startDistance = startDistance
        self.avgHorizontalAccuracy = avgHorizontalAccuracy
        self.sampleCount = sampleCount
        self.isReliable = isReliable
    }
}

/// Summary of all metrics for a session
struct MetricsSummary: Codable {
    let sessionId: UUID
    let computedAt: Date
    let results: [MetricResult]
    
    // Configuration used for calculation
    let accuracyThreshold: Double  // meters
    let useFilteredData: Bool
    
    init(
        sessionId: UUID,
        computedAt: Date = Date(),
        results: [MetricResult] = [],
        accuracyThreshold: Double = 50.0,
        useFilteredData: Bool = false
    ) {
        self.sessionId = sessionId
        self.computedAt = computedAt
        self.results = results
        self.accuracyThreshold = accuracyThreshold
        self.useFilteredData = useFilteredData
    }
    
    /// Get result for a specific metric type
    func result(for type: MetricType) -> MetricResult? {
        results.first { $0.metricType == type }
    }
}

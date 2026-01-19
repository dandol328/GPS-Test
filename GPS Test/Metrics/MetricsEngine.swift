//
//  MetricsEngine.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// Engine for computing performance metrics from LocationSample data
class MetricsEngine {
    
    // MARK: - Metric Thresholds
    
    /// Distance thresholds in meters
    private struct DistanceThresholds {
        static let sixtyFeet = 18.288        // 60 ft
        static let eighthMile = 201.168      // 1/8 mile
        static let quarterMile = 402.336     // 1/4 mile
    }
    
    /// Speed thresholds in m/s
    private struct SpeedThresholds {
        static let mph2 = 0.894              // 2 mph - movement detection
        static let mph30 = 13.4112           // 30 mph
        static let mph40 = 17.8816           // 40 mph
        static let mph60 = 26.8224           // 60 mph
        static let mph70 = 31.2928           // 70 mph
        static let mph80 = 35.7632           // 80 mph
        static let mph100 = 44.704           // 100 mph
    }
    
    // MARK: - Public API
    
    /// Compute all performance metrics for a recording session
    /// - Parameters:
    ///   - session: The recording session containing location samples
    ///   - accuracyThreshold: Maximum acceptable horizontal accuracy in meters (default: 50.0)
    /// - Returns: MetricsSummary containing all computed metrics
    func computeMetrics(session: RecordingSession, accuracyThreshold: Double = 50.0) -> MetricsSummary {
        // Validate we have enough samples
        guard session.samples.count >= 2 else {
            return MetricsSummary(
                sessionId: session.id,
                results: [],
                accuracyThreshold: accuracyThreshold
            )
        }
        
        // Detect start index (first sample where speed > 2 mph after being below)
        guard let startIndex = detectStart(samples: session.samples) else {
            // No valid start detected
            return MetricsSummary(
                sessionId: session.id,
                results: [],
                accuracyThreshold: accuracyThreshold
            )
        }
        
        // Calculate cumulative distances for all samples starting from startIndex
        let cumulativeDistances = calculateCumulativeDistances(
            samples: session.samples,
            startIndex: startIndex
        )
        
        var results: [MetricResult] = []
        
        // Compute distance-based metrics
        if let result = computeDistanceMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetDistance: DistanceThresholds.sixtyFeet,
            metricType: .sixtyFeet,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeDistanceMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetDistance: DistanceThresholds.eighthMile,
            metricType: .eighthMile,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeDistanceMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetDistance: DistanceThresholds.quarterMile,
            metricType: .quarterMile,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        // Compute speed-based metrics (0 to X)
        if let result = computeSpeedMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetSpeed: SpeedThresholds.mph30,
            metricType: .zeroToThirty,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeSpeedMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetSpeed: SpeedThresholds.mph40,
            metricType: .zeroToForty,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeSpeedMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetSpeed: SpeedThresholds.mph60,
            metricType: .zeroToSixty,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeSpeedMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetSpeed: SpeedThresholds.mph80,
            metricType: .zeroToEighty,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeSpeedMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            targetSpeed: SpeedThresholds.mph100,
            metricType: .zeroToHundred,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        // Compute rolling interval metrics
        if let result = computeRollingIntervalMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            startSpeed: SpeedThresholds.mph30,
            endSpeed: SpeedThresholds.mph70,
            metricType: .thirtyToSeventy,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        if let result = computeRollingIntervalMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            startSpeed: SpeedThresholds.mph40,
            endSpeed: SpeedThresholds.mph100,
            metricType: .fortyToHundred,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        // Compute braking metric (60-0)
        if let result = computeBrakingMetric(
            samples: session.samples,
            cumulativeDistances: cumulativeDistances,
            startIndex: startIndex,
            startSpeed: SpeedThresholds.mph60,
            endSpeed: 0.0,
            metricType: .sixtyToZero,
            accuracyThreshold: accuracyThreshold
        ) {
            results.append(result)
        }
        
        return MetricsSummary(
            sessionId: session.id,
            results: results,
            accuracyThreshold: accuracyThreshold
        )
    }
    
    // MARK: - Start Detection
    
    /// Detect the start of a run (first sample where speed > 2 mph after being below threshold)
    /// - Parameter samples: Array of location samples
    /// - Returns: Index of the start sample, or nil if no valid start found
    private func detectStart(samples: [LocationSample]) -> Int? {
        guard samples.count >= 2 else { return nil }
        
        let threshold = SpeedThresholds.mph2
        
        // Find first transition from below threshold to above threshold
        for i in 0..<(samples.count - 1) {
            if samples[i].speed <= threshold && samples[i + 1].speed > threshold {
                return i + 1  // Return the first sample above threshold
            }
        }
        
        // Alternative: if first sample is already above threshold, use it
        if samples[0].speed > threshold {
            return 0
        }
        
        return nil
    }
    
    // MARK: - Distance Calculation
    
    /// Calculate cumulative distances from start index using haversine formula
    /// - Parameters:
    ///   - samples: Array of location samples
    ///   - startIndex: Index to start from (typically the detected start)
    /// - Returns: Array of cumulative distances in meters (same length as samples)
    private func calculateCumulativeDistances(samples: [LocationSample], startIndex: Int) -> [Double] {
        var distances = Array(repeating: 0.0, count: samples.count)
        
        guard startIndex < samples.count else { return distances }
        
        // Distance at start is 0
        distances[startIndex] = 0.0
        
        // Calculate cumulative distances forward from start
        for i in (startIndex + 1)..<samples.count {
            let prev = samples[i - 1]
            let curr = samples[i]
            let segmentDistance = haversineDistance(
                lat1: prev.latitude,
                lon1: prev.longitude,
                lat2: curr.latitude,
                lon2: curr.longitude
            )
            distances[i] = distances[i - 1] + segmentDistance
        }
        
        // Calculate distances backward from start (if needed for braking metrics)
        if startIndex > 0 {
            for i in stride(from: startIndex - 1, through: 0, by: -1) {
                let nextSample = samples[i + 1]  // Sample after current (toward start)
                let currentSample = samples[i]
                let segmentDistance = haversineDistance(
                    lat1: currentSample.latitude,
                    lon1: currentSample.longitude,
                    lat2: nextSample.latitude,
                    lon2: nextSample.longitude
                )
                distances[i] = distances[i + 1] - segmentDistance
            }
        }
        
        return distances
    }
    
    /// Haversine formula for calculating distance between two lat/lon points
    /// - Parameters:
    ///   - lat1: Latitude of first point in degrees
    ///   - lon1: Longitude of first point in degrees
    ///   - lat2: Latitude of second point in degrees
    ///   - lon2: Longitude of second point in degrees
    /// - Returns: Distance in meters
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
    
    // MARK: - Linear Interpolation
    
    /// Linear interpolation to find y value at a given x
    /// - Parameters:
    ///   - x0: First x value
    ///   - y0: First y value
    ///   - x1: Second x value
    ///   - y1: Second y value
    ///   - x: Target x value to interpolate
    /// - Returns: Interpolated y value
    private func linearInterpolate(x0: Double, y0: Double, x1: Double, y1: Double, x: Double) -> Double {
        // Handle edge cases
        guard x1 != x0 else { return y0 }
        
        // Linear interpolation formula: y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
        return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    }
    
    // MARK: - Distance-Based Metrics
    
    /// Compute a distance-based metric (60ft, 1/8 mile, 1/4 mile)
    /// - Parameters:
    ///   - samples: Array of location samples
    ///   - cumulativeDistances: Pre-calculated cumulative distances
    ///   - startIndex: Index where run started
    ///   - targetDistance: Target distance in meters
    ///   - metricType: Type of metric being computed
    ///   - accuracyThreshold: Accuracy threshold for reliability
    /// - Returns: MetricResult if threshold reached, nil otherwise
    private func computeDistanceMetric(
        samples: [LocationSample],
        cumulativeDistances: [Double],
        startIndex: Int,
        targetDistance: Double,
        metricType: MetricType,
        accuracyThreshold: Double
    ) -> MetricResult? {
        guard startIndex < samples.count else { return nil }
        
        let startSample = samples[startIndex]
        let startDistance = cumulativeDistances[startIndex]
        let targetAbsoluteDistance = startDistance + targetDistance
        
        // Find the index where we cross the target distance
        var endIndex: Int?
        for i in startIndex..<samples.count {
            if cumulativeDistances[i] >= targetAbsoluteDistance {
                endIndex = i
                break
            }
        }
        
        guard let endIdx = endIndex else { return nil }
        
        // Calculate interpolated values at exact distance threshold
        let interpolatedTimestamp: Date
        let interpolatedSpeed: Double
        
        if endIdx == startIndex {
            // Edge case: threshold reached at start
            interpolatedTimestamp = samples[endIdx].timestamp
            interpolatedSpeed = samples[endIdx].speed
        } else {
            let prevIndex = endIdx - 1
            let prevSample = samples[prevIndex]
            let currSample = samples[endIdx]
            
            let prevDistance = cumulativeDistances[prevIndex]
            let currDistance = cumulativeDistances[endIdx]
            
            // Interpolate timestamp
            let prevTime = prevSample.timestamp.timeIntervalSince1970
            let currTime = currSample.timestamp.timeIntervalSince1970
            let interpolatedTime = linearInterpolate(
                x0: prevDistance,
                y0: prevTime,
                x1: currDistance,
                y1: currTime,
                x: targetAbsoluteDistance
            )
            interpolatedTimestamp = Date(timeIntervalSince1970: interpolatedTime)
            
            // Interpolate speed at exact distance
            interpolatedSpeed = linearInterpolate(
                x0: prevDistance,
                y0: prevSample.speed,
                x1: currDistance,
                y1: currSample.speed,
                x: targetAbsoluteDistance
            )
        }
        
        // Calculate metrics
        let elapsedTime = interpolatedTimestamp.timeIntervalSince(startSample.timestamp)
        
        // Find peak speed in the interval
        let peakSpeed = samples[startIndex...endIdx].map { $0.speed }.max() ?? 0.0
        
        // Calculate average horizontal accuracy
        let totalAccuracy = samples[startIndex...endIdx].reduce(0.0) { $0 + $1.horizontalAccuracy }
        let avgAccuracy = totalAccuracy / Double(endIdx - startIndex + 1)
        
        let sampleCount = endIdx - startIndex + 1
        let isReliable = avgAccuracy < accuracyThreshold
        
        return MetricResult(
            metricType: metricType,
            elapsedTime: elapsedTime,
            startTimestamp: startSample.timestamp,
            endTimestamp: interpolatedTimestamp,
            trapSpeed: interpolatedSpeed,
            peakSpeed: peakSpeed,
            distance: targetAbsoluteDistance,
            startDistance: startDistance,
            avgHorizontalAccuracy: avgAccuracy,
            sampleCount: sampleCount,
            isReliable: isReliable
        )
    }
    
    // MARK: - Speed-Based Metrics
    
    /// Compute a speed-based metric (0-30, 0-60, etc.)
    /// - Parameters:
    ///   - samples: Array of location samples
    ///   - cumulativeDistances: Pre-calculated cumulative distances
    ///   - startIndex: Index where run started
    ///   - targetSpeed: Target speed in m/s
    ///   - metricType: Type of metric being computed
    ///   - accuracyThreshold: Accuracy threshold for reliability
    /// - Returns: MetricResult if threshold reached, nil otherwise
    private func computeSpeedMetric(
        samples: [LocationSample],
        cumulativeDistances: [Double],
        startIndex: Int,
        targetSpeed: Double,
        metricType: MetricType,
        accuracyThreshold: Double
    ) -> MetricResult? {
        guard startIndex < samples.count else { return nil }
        
        let startSample = samples[startIndex]
        let startDistance = cumulativeDistances[startIndex]
        
        // Find the index where we reach or exceed target speed
        var endIndex: Int?
        for i in startIndex..<samples.count {
            if samples[i].speed >= targetSpeed {
                endIndex = i
                break
            }
        }
        
        guard let endIdx = endIndex else { return nil }
        
        // Calculate interpolated values at exact speed threshold
        let interpolatedTimestamp: Date
        let interpolatedDistance: Double
        
        if endIdx == startIndex {
            // Edge case: already at target speed at start
            interpolatedTimestamp = samples[endIdx].timestamp
            interpolatedDistance = cumulativeDistances[endIdx]
        } else {
            let prevIndex = endIdx - 1
            let prevSample = samples[prevIndex]
            let currSample = samples[endIdx]
            
            // Interpolate timestamp when exact speed is reached
            let interpolatedTime = linearInterpolate(
                x0: prevSample.speed,
                y0: prevSample.timestamp.timeIntervalSince1970,
                x1: currSample.speed,
                y1: currSample.timestamp.timeIntervalSince1970,
                x: targetSpeed
            )
            interpolatedTimestamp = Date(timeIntervalSince1970: interpolatedTime)
            
            // Interpolate distance at exact speed
            interpolatedDistance = linearInterpolate(
                x0: prevSample.speed,
                y0: cumulativeDistances[prevIndex],
                x1: currSample.speed,
                y1: cumulativeDistances[endIdx],
                x: targetSpeed
            )
        }
        
        // Calculate metrics
        let elapsedTime = interpolatedTimestamp.timeIntervalSince(startSample.timestamp)
        
        // Find peak speed in the interval
        let peakSpeed = samples[startIndex...endIdx].map { $0.speed }.max() ?? 0.0
        
        // Calculate average horizontal accuracy
        let totalAccuracy = samples[startIndex...endIdx].reduce(0.0) { $0 + $1.horizontalAccuracy }
        let avgAccuracy = totalAccuracy / Double(endIdx - startIndex + 1)
        
        let sampleCount = endIdx - startIndex + 1
        let isReliable = avgAccuracy < accuracyThreshold
        
        return MetricResult(
            metricType: metricType,
            elapsedTime: elapsedTime,
            startTimestamp: startSample.timestamp,
            endTimestamp: interpolatedTimestamp,
            trapSpeed: targetSpeed,  // Trap speed is the target speed for speed-based metrics
            peakSpeed: peakSpeed,
            distance: interpolatedDistance,
            startDistance: startDistance,
            avgHorizontalAccuracy: avgAccuracy,
            sampleCount: sampleCount,
            isReliable: isReliable
        )
    }
    
    // MARK: - Rolling Interval Metrics
    
    /// Compute a rolling interval metric (30-70, 40-100)
    /// - Parameters:
    ///   - samples: Array of location samples
    ///   - cumulativeDistances: Pre-calculated cumulative distances
    ///   - startIndex: Index where run started
    ///   - startSpeed: Starting speed threshold in m/s
    ///   - endSpeed: Ending speed threshold in m/s
    ///   - metricType: Type of metric being computed
    ///   - accuracyThreshold: Accuracy threshold for reliability
    /// - Returns: MetricResult if both thresholds reached, nil otherwise
    private func computeRollingIntervalMetric(
        samples: [LocationSample],
        cumulativeDistances: [Double],
        startIndex: Int,
        startSpeed: Double,
        endSpeed: Double,
        metricType: MetricType,
        accuracyThreshold: Double
    ) -> MetricResult? {
        guard startIndex < samples.count else { return nil }
        
        // Find where we first reach start speed
        var intervalStartIndex: Int?
        for i in startIndex..<samples.count {
            if samples[i].speed >= startSpeed {
                intervalStartIndex = i
                break
            }
        }
        
        guard let startIdx = intervalStartIndex else { return nil }
        
        // Find where we reach end speed (starting from interval start)
        var intervalEndIndex: Int?
        for i in startIdx..<samples.count {
            if samples[i].speed >= endSpeed {
                intervalEndIndex = i
                break
            }
        }
        
        guard let endIdx = intervalEndIndex else { return nil }
        
        // Interpolate at start speed threshold
        let intervalStartTimestamp: Date
        let intervalStartDistance: Double
        
        if startIdx == 0 || startIdx == startIndex || samples[startIdx - 1].speed >= startSpeed {
            // Already at or above start speed, no interpolation needed
            intervalStartTimestamp = samples[startIdx].timestamp
            intervalStartDistance = cumulativeDistances[startIdx]
        } else {
            let prevIndex = startIdx - 1
            let prevSample = samples[prevIndex]
            let currSample = samples[startIdx]
            
            let interpolatedTime = linearInterpolate(
                x0: prevSample.speed,
                y0: prevSample.timestamp.timeIntervalSince1970,
                x1: currSample.speed,
                y1: currSample.timestamp.timeIntervalSince1970,
                x: startSpeed
            )
            intervalStartTimestamp = Date(timeIntervalSince1970: interpolatedTime)
            
            intervalStartDistance = linearInterpolate(
                x0: prevSample.speed,
                y0: cumulativeDistances[prevIndex],
                x1: currSample.speed,
                y1: cumulativeDistances[startIdx],
                x: startSpeed
            )
        }
        
        // Interpolate at end speed threshold
        let intervalEndTimestamp: Date
        let intervalEndDistance: Double
        
        if endIdx == 0 || endIdx == startIdx || samples[endIdx - 1].speed >= endSpeed {
            // Already at or above end speed, no interpolation needed
            intervalEndTimestamp = samples[endIdx].timestamp
            intervalEndDistance = cumulativeDistances[endIdx]
        } else {
            let prevIndex = endIdx - 1
            let prevSample = samples[prevIndex]
            let currSample = samples[endIdx]
            
            let interpolatedTime = linearInterpolate(
                x0: prevSample.speed,
                y0: prevSample.timestamp.timeIntervalSince1970,
                x1: currSample.speed,
                y1: currSample.timestamp.timeIntervalSince1970,
                x: endSpeed
            )
            intervalEndTimestamp = Date(timeIntervalSince1970: interpolatedTime)
            
            intervalEndDistance = linearInterpolate(
                x0: prevSample.speed,
                y0: cumulativeDistances[prevIndex],
                x1: currSample.speed,
                y1: cumulativeDistances[endIdx],
                x: endSpeed
            )
        }
        
        // Calculate metrics
        let elapsedTime = intervalEndTimestamp.timeIntervalSince(intervalStartTimestamp)
        
        // Find peak speed in the interval
        let peakSpeed = samples[startIdx...endIdx].map { $0.speed }.max() ?? 0.0
        
        // Calculate average horizontal accuracy
        let totalAccuracy = samples[startIdx...endIdx].reduce(0.0) { $0 + $1.horizontalAccuracy }
        let avgAccuracy = totalAccuracy / Double(endIdx - startIdx + 1)
        
        let sampleCount = endIdx - startIdx + 1
        let isReliable = avgAccuracy < accuracyThreshold
        
        return MetricResult(
            metricType: metricType,
            elapsedTime: elapsedTime,
            startTimestamp: intervalStartTimestamp,
            endTimestamp: intervalEndTimestamp,
            trapSpeed: endSpeed,  // Trap speed is the end speed
            peakSpeed: peakSpeed,
            distance: intervalEndDistance,
            startDistance: intervalStartDistance,
            avgHorizontalAccuracy: avgAccuracy,
            sampleCount: sampleCount,
            isReliable: isReliable
        )
    }
    
    // MARK: - Braking Metrics
    
    /// Compute a braking metric (60-0)
    /// - Parameters:
    ///   - samples: Array of location samples
    ///   - cumulativeDistances: Pre-calculated cumulative distances
    ///   - startIndex: Index where run started
    ///   - startSpeed: Speed to brake from in m/s
    ///   - endSpeed: Speed to brake to in m/s (typically 0)
    ///   - metricType: Type of metric being computed
    ///   - accuracyThreshold: Accuracy threshold for reliability
    /// - Returns: MetricResult if braking event found, nil otherwise
    private func computeBrakingMetric(
        samples: [LocationSample],
        cumulativeDistances: [Double],
        startIndex: Int,
        startSpeed: Double,
        endSpeed: Double,
        metricType: MetricType,
        accuracyThreshold: Double
    ) -> MetricResult? {
        guard startIndex < samples.count else { return nil }
        
        // Find where we first reach the start speed (60 mph)
        var brakingStartIndex: Int?
        for i in startIndex..<samples.count {
            if samples[i].speed >= startSpeed {
                brakingStartIndex = i
                break
            }
        }
        
        guard let startIdx = brakingStartIndex else { return nil }
        
        // From the braking start, find where speed drops to or below end speed
        var brakingEndIndex: Int?
        for i in (startIdx + 1)..<samples.count {
            if samples[i].speed <= endSpeed {
                brakingEndIndex = i
                break
            }
        }
        
        guard let endIdx = brakingEndIndex else { return nil }
        
        // Interpolate at braking start (when reaching start speed)
        let brakingStartTimestamp: Date
        let brakingStartDistance: Double
        
        if startIdx == 0 || samples[startIdx - 1].speed >= startSpeed {
            // Already at or above start speed, no interpolation needed
            brakingStartTimestamp = samples[startIdx].timestamp
            brakingStartDistance = cumulativeDistances[startIdx]
        } else {
            let prevIndex = startIdx - 1
            let prevSample = samples[prevIndex]
            let currSample = samples[startIdx]
            
            let interpolatedTime = linearInterpolate(
                x0: prevSample.speed,
                y0: prevSample.timestamp.timeIntervalSince1970,
                x1: currSample.speed,
                y1: currSample.timestamp.timeIntervalSince1970,
                x: startSpeed
            )
            brakingStartTimestamp = Date(timeIntervalSince1970: interpolatedTime)
            
            brakingStartDistance = linearInterpolate(
                x0: prevSample.speed,
                y0: cumulativeDistances[prevIndex],
                x1: currSample.speed,
                y1: cumulativeDistances[startIdx],
                x: startSpeed
            )
        }
        
        // Interpolate at braking end (when reaching end speed)
        let brakingEndTimestamp: Date
        let brakingEndDistance: Double
        
        let prevIndex = endIdx - 1
        let prevSample = samples[prevIndex]
        let currSample = samples[endIdx]
        
        let interpolatedTime = linearInterpolate(
            x0: prevSample.speed,
            y0: prevSample.timestamp.timeIntervalSince1970,
            x1: currSample.speed,
            y1: currSample.timestamp.timeIntervalSince1970,
            x: endSpeed
        )
        brakingEndTimestamp = Date(timeIntervalSince1970: interpolatedTime)
        
        brakingEndDistance = linearInterpolate(
            x0: prevSample.speed,
            y0: cumulativeDistances[prevIndex],
            x1: currSample.speed,
            y1: cumulativeDistances[endIdx],
            x: endSpeed
        )
        
        // Calculate metrics
        let elapsedTime = brakingEndTimestamp.timeIntervalSince(brakingStartTimestamp)
        
        // Calculate stopping distance (should be positive since we're moving forward while braking)
        // For braking, end distance should be greater than start distance
        let stoppingDistance = brakingEndDistance - brakingStartDistance
        
        // Validate stopping distance is non-negative
        // Negative value would indicate calculation error or data corruption
        guard stoppingDistance >= 0 else {
            // This should not happen with valid GPS data - indicates a serious calculation error
            // Could be caused by: incorrect cumulative distance calculation, corrupted samples,
            // or samples not in chronological order
            return nil
        }
        
        // For braking, peak speed is the start speed
        let peakSpeed = samples[startIdx...endIdx].map { $0.speed }.max() ?? startSpeed
        
        // Calculate average horizontal accuracy
        let totalAccuracy = samples[startIdx...endIdx].reduce(0.0) { $0 + $1.horizontalAccuracy }
        let avgAccuracy = totalAccuracy / Double(endIdx - startIdx + 1)
        
        let sampleCount = endIdx - startIdx + 1
        let isReliable = avgAccuracy < accuracyThreshold
        
        return MetricResult(
            metricType: metricType,
            elapsedTime: elapsedTime,
            startTimestamp: brakingStartTimestamp,
            endTimestamp: brakingEndTimestamp,
            trapSpeed: endSpeed,  // Final speed (0 for 60-0)
            peakSpeed: peakSpeed,
            distance: stoppingDistance,  // Store stopping distance
            startDistance: brakingStartDistance,
            avgHorizontalAccuracy: avgAccuracy,
            sampleCount: sampleCount,
            isReliable: isReliable
        )
    }
}

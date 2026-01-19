//
//  FixType.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation

/// GNSS fix type enumeration
enum FixType: String, Codable, CaseIterable {
    case noFix = "noFix"
    case twoD = "twoD"
    case threeD = "threeD"
    case dgps = "dgps"
    case rtk = "rtk"
    case unknown = "unknown"
    
    /// Convert from BLE fix status value
    /// - Parameter bleFixStatus: Fix status from BLE protocol (0=no fix, 2=2D, 3=3D)
    /// - Returns: Corresponding FixType
    static func from(bleFixStatus: Int) -> FixType {
        switch bleFixStatus {
        case 0:
            return .noFix
        case 2:
            return .twoD
        case 3:
            return .threeD
        default:
            return .unknown
        }
    }
    
    var displayName: String {
        switch self {
        case .noFix:
            return "No Fix"
        case .twoD:
            return "2D Fix"
        case .threeD:
            return "3D Fix"
        case .dgps:
            return "DGPS"
        case .rtk:
            return "RTK"
        case .unknown:
            return "Unknown"
        }
    }
}

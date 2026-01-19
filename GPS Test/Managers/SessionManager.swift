//
//  SessionManager.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import Foundation
import Combine

/// Manages recording sessions with persistent storage
class SessionManager: ObservableObject {
    @Published var currentSession: RecordingSession?
    @Published var isRecording: Bool = false
    @Published var sessions: [RecordingSession] = []
    
    // Configuration
    @Published var sampleRateHz: Int = 25  // Default 25 Hz, max 25 Hz
    
    private let storageKey = "recordedSessions"
    private let maxStoredSessions = 50
    
    init() {
        loadSessions()
    }
    
    /// Start a new recording session
    func startRecording(sampleRateHz: Int = 25) {
        guard !isRecording else { return }
        
        let rate = min(sampleRateHz, 25)  // Cap at 25 Hz per requirement
        currentSession = RecordingSession(
            startTime: Date(),
            sampleRateHz: rate
        )
        isRecording = true
        self.sampleRateHz = rate
    }
    
    /// Stop the current recording session
    func stopRecording() -> RecordingSession? {
        guard isRecording, var session = currentSession else { return nil }
        
        session.endTime = Date()
        isRecording = false
        
        // Save to storage
        saveSession(session)
        
        let completed = session
        currentSession = nil
        return completed
    }
    
    /// Add a location sample to the current recording session
    func addSample(_ sample: LocationSample) {
        guard isRecording, currentSession != nil else { return }
        currentSession?.samples.append(sample)
    }
    
    /// Create a location sample from BLE data and add to current session
    func addBLESample(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        speed: Double,
        heading: Double,
        fixStatus: Int,
        satellites: Int,
        pdop: Double
    ) {
        guard isRecording else { return }
        
        let sample = LocationSample.fromBLE(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speed: speed,
            heading: heading,
            fixStatus: fixStatus,
            satellites: satellites,
            pdop: pdop
        )
        
        addSample(sample)
    }
    
    /// Save a session to persistent storage
    private func saveSession(_ session: RecordingSession) {
        sessions.insert(session, at: 0)
        
        // Keep only the most recent sessions
        if sessions.count > maxStoredSessions {
            sessions = Array(sessions.prefix(maxStoredSessions))
        }
        
        persistSessions()
    }
    
    /// Delete a session
    func deleteSession(_ session: RecordingSession) {
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }
    
    /// Clear all sessions
    func clearAllSessions() {
        sessions.removeAll()
        persistSessions()
    }
    
    // MARK: - Persistence
    
    private func persistSessions() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([RecordingSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
            sessions = []
        }
    }
}

//
//  SessionsView.swift
//  GPS Test
//
//  Created by GPS Test Agent
//

import SwiftUI

struct SessionsView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var settings: UserSettings
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: RecordingSession?
    
    var body: some View {
        NavigationView {
            Group {
                if sessionManager.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Sessions Recorded")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Start a recording session from the Timing tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(sessionManager.sessions) { session in
                            NavigationLink(destination: SessionDetailView(
                                session: session,
                                sessionManager: sessionManager,
                                settings: settings
                            )) {
                                SessionRowView(session: session, settings: settings)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                if !sessionManager.sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                sessionToDelete = nil
                                showingDeleteAlert = true
                            }) {
                                Label("Clear All Sessions", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Delete Session", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        sessionManager.deleteSession(session)
                    } else {
                        sessionManager.clearAllSessions()
                    }
                    sessionToDelete = nil
                }
            } message: {
                if sessionToDelete != nil {
                    Text("Are you sure you want to delete this session? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete all sessions? This action cannot be undone.")
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: RecordingSession
    @ObservedObject var settings: UserSettings
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let name = session.name, !name.isEmpty {
                    Text(name)
                        .font(.headline)
                } else {
                    Text(dateFormatter.string(from: session.startTime))
                        .font(.headline)
                }
                Spacer()
                if session.samples.count < 10 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(session.samples.count)", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(String(format: "%.1fs", session.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if session.totalDistance > 0 {
                    Label(String(format: "%.0fm", session.totalDistance), systemImage: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if session.maxSpeed > 0 {
                    Label(String(format: "%.1f %@", settings.convertSpeed(session.maxSpeed), settings.speedUnitLabel()), 
                          systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionsView(sessionManager: SessionManager(), settings: UserSettings())
}

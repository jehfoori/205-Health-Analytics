import SwiftUI

struct HistoryView: View {
    @StateObject private var zoneStore = ZoneDataStore.shared
    @StateObject private var sessionStore = SessionDataStore.shared
    
    var body: some View {
        NavigationView {
            List {
                if zoneStore.zones.isEmpty {
                    VStack(spacing: 10) {
                        Text("No zones added yet.")
                            .font(.headline)
                        Text("Go to the Map tab to start your journey.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(zoneStore.zones) { zone in
                        // Link to the Detail View for this specific zone
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(zone.name)
                                        .font(.headline)
                                    Text("\(sessionStore.sessions(for: zone.id).count) Sessions recorded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Your Progress")
        }
    }
}

// The Details: A list of every time you visited this zone
struct ZoneDetailView: View {
    let zone: ChallengeZone
    @ObservedObject var sessionStore = SessionDataStore.shared
    
    var body: some View {
        List {
            // Section 1: Aggregate Stats
            Section(header: Text("Summary")) {
                HStack {
                    StatBox(label: "Peak HR", value: "\(formattedPeak) bpm")
                    Divider()
                    StatBox(label: "Total Time", value: formattedTotalTime)
                }
            }
            
            // Section 2: The History Log
            Section(header: Text("Session Log")) {
                let history = sessionStore.sessions(for: zone.id)
                
                if history.isEmpty {
                    Text("No sessions recorded here yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(history) { session in
                        SessionRow(session: session)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(zone.name)
    }
    
    // Computed properties for the Summary Box
    var formattedPeak: Int {
        let sessions = sessionStore.sessions(for: zone.id)
        return Int(sessions.map { $0.peakHR }.max() ?? 0)
    }
    
    var formattedTotalTime: String {
        let sessions = sessionStore.sessions(for: zone.id)
        let total = sessions.map { $0.duration }.reduce(0, +)
        return formatDuration(total)
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0m"
    }
}

// MARK: - Helper Views

struct SessionRow: View {
    let session: ExposureSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. Header: Date and Duration
            HStack {
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Divider()
            
            // 2. The Reality Check Stats
            HStack(spacing: 12) {
                // Mind Score
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text("Mind: \(Int(session.subjectiveRating))")
                }
                .font(.caption)
                .foregroundColor(colorForRating(session.subjectiveRating))
                
                // Body Score
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                    Text("Body: \(Int(session.physiologicalScore))")
                }
                .font(.caption)
                .foregroundColor(colorForRating(session.physiologicalScore))
                
                Spacer()
                
                // Discrepancy Badge
                if session.discrepancy > 20 {
                    Text("False Alarm")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            // 3. Journal Note (if exists)
            if let note = session.journalNote, !note.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }
    
    func colorForRating(_ val: Double) -> Color {
        return val > 70 ? .red : (val > 40 ? .orange : .blue)
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0m"
    }
}

struct StatBox: View {
    let label: String
    let value: String
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

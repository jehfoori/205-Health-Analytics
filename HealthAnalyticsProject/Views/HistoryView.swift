import SwiftUI

struct HistoryView: View {
    @StateObject private var zoneStore = ZoneDataStore.shared
    @StateObject private var sessionStore = SessionDataStore.shared
    
    var body: some View {
        NavigationView {
            List {
                if zoneStore.zones.isEmpty {
                    Text("No zones added yet. Go to the Map tab!")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(zoneStore.zones) { zone in
                        // Link to the Detail View for this specific zone
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(zone.name)
                                        .font(.headline)
                                    Text("\(sessionStore.sessions(for: zone.id).count) Sessions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // Quick indicator of progress (Optional: Show last session date)
                            }
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
            // Section 1: The "Why" (We will put a chart here next time)
            Section(header: Text("Summary")) {
                HStack {
                    StatBox(label: "Peak Anxiety", value: "\(formattedPeak) bpm")
                    Divider()
                    StatBox(label: "Total Time", value: formattedTotalTime)
                }
            }
            
            // Section 2: The History Log
            Section(header: Text("History Log")) {
                let history = sessionStore.sessions(for: zone.id)
                
                if history.isEmpty {
                    Text("No sessions recorded here yet.")
                } else {
                    ForEach(history) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .bold()
                                Text("Duration: \(formatDuration(session.duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // The "Score"
                            VStack(alignment: .trailing) {
                                Text("\(Int(session.peakHR)) bpm")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("Peak")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(zone.name)
    }
    
    // Computed properties for the Summary Box
    var formattedPeak: Int {
        let sessions = sessionStore.sessions(for: zone.id)
        // Find the highest HR ever recorded across all sessions
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
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00"
    }
}

// Helper View for the Summary stats
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

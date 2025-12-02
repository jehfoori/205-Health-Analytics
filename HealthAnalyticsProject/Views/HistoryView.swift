import SwiftUI
import Charts

func colorForRating(_ val: Double) -> Color {
    return val > 70 ? .red : (val > 40 ? .orange : .blue)
}

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
                        Text("Go to the Explore tab to start your journey.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Wrap the ForEach so we can attach .onDelete to it
                    ForEach(zoneStore.zones) { zone in
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    // find the index and reuse your existing deleteZone(at:)
                                    if let index = zoneStore.zones.firstIndex(where: { $0.id == zone.id }) {
                                        zoneStore.deleteZone(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Image(systemName: "trash")    // 👈 icon-only
                                }
                            }
                    }
                    // This enables swipe-to-delete & Edit mode delete for zones
                    .onDelete(perform: zoneStore.deleteZone)
                    
                }
            }
            .navigationTitle("Your Progress")
            .toolbar {
                // Optional: standard Edit button to show delete controls
                EditButton()
            }
        }
    }
}


// The Details: A list of every time you visited this zone
struct ZoneDetailView: View {
    let zone: ChallengeZone
    @ObservedObject var sessionStore = SessionDataStore.shared
    
    var body: some View {
        List {
            // Section 1: Progress Chart (Longitudinal)
            Section(header: Text("Progress Over Time")) {
                if history.count > 1 {
                    Chart {
                        ForEach(history) { session in
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("SUDS", session.subjectiveRating)
                            )
                            .foregroundStyle(.blue)
                            .symbol(by: .value("Metric", "Mind (SUDS)"))
                            
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("Body", session.physiologicalScore)
                            )
                            .foregroundStyle(.red)
                            .symbol(by: .value("Metric", "Body Score"))
                        }
                        
                    }.chartForegroundStyleScale([
                        "Mind (SUDS)" : Color.blue,
                        "Body Score"  : Color.red
                    ])
                    .frame(height: 200)
                    .padding(.vertical)
                } else {
                    Text("Complete more sessions to see trends.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Section 2: The Log
            Section(header: Text("History")) {
                if history.isEmpty {
                    Text("No sessions recorded here yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(history) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session)
                                .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                sessionStore.deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(zone.name)
    }
    
    // Computed props
    var history: [ExposureSession] {
        sessionStore.sessions(for: zone.id).reversed() // Chronological order for chart
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
            
            // 2. The Reality Check Stats
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text("Mind Score: \(Int(session.subjectiveRating))") 
                }
                .font(.caption)
                .foregroundColor(colorForRating(session.subjectiveRating))
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                    Text("Body Score: \(Int(session.physiologicalScore))")
                }
                .font(.caption)
                .foregroundColor(colorForRating(session.physiologicalScore))
                
                Spacer()
                /*
                if session.discrepancy > 20 {
                    Text("False Alarm")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }*/
            }
        }
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

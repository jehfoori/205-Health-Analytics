import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: ExposureSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 1. Header Info
                VStack(spacing: 8) {
                    Text(session.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(formatDuration(session.duration), systemImage: "clock")
                        Divider().frame(height: 12)
                        Label("\(Int(session.peakHR)) bpm Peak", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }
                    .font(.caption)
                }
                .padding(.top)
                
                Divider()
                
                // 2. The Habituation Curve (Graph)
                VStack(alignment: .leading) {
                    Text("Heart Rate Response")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if !session.hrReadings.isEmpty {
                        Chart {
                            ForEach(Array(session.hrReadings.enumerated()), id: \.offset) { index, bpm in
                                LineMark(
                                    x: .value("Time", index),
                                    y: .value("BPM", bpm)
                                )
                                .foregroundStyle(Color.red.gradient)
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: .automatic(includesZero: false))
                        .padding()
                    } else {
                        Text("No heart rate data recorded for this session.")
                            .font(.caption)
                            .italic()
                            .padding()
                    }
                }
                
                // 3. Stats Grid
                HStack {
                    StatBox(label: "Mind Score (SUDS)", value: "\(Int(session.subjectiveRating))")
                    Divider()
                    StatBox(label: "Body Score", value: "\(Int(session.physiologicalScore))")
                }
                .padding(.horizontal)
                
                // 4. Journal Note
                if let note = session.journalNote, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Journal")
                            .font(.headline)
                        
                        Text(note)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0m"
    }
}

import SwiftUI
import Charts

struct PostSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    
    let zone: ChallengeZone
    
    // User Inputs
    @State private var subjectiveRating: Double = 50
    @State private var journalNote: String = ""
    @State private var showResults = false
    
    // Help Sheets
    @State private var showSUDSHelp = false
    @State private var showGraphHelp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !showResults {
                    // PHASE 1: The Input (Unchanged)
                    HStack {
                        Text("How intense was that?")
                            .font(.title2.bold())
                        Button(action: { showSUDSHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("\(Int(subjectiveRating))/100")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(colorForRating(subjectiveRating))
                    
                    Slider(value: $subjectiveRating, in: 0...100, step: 1)
                        .accentColor(colorForRating(subjectiveRating))
                        .padding()
                    
                    Text("Subjective Units of Distress (SUDS)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("See Session Analysis") {
                        withAnimation { showResults = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                } else {
                    // PHASE 2: The Analysis (UPDATED)
                    ScrollView {
                        VStack(spacing: 25) {
                            // 1. The Habituation Curve Graph
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Habituation Curve")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: { showGraphHelp = true }) {
                                        Image(systemName: "questionmark.circle")
                                    }
                                }
                                
                                Chart {
                                    ForEach(Array(sessionManager.hrReadings.enumerated()), id: \.offset) { index, bpm in
                                        LineMark(
                                            x: .value("Time", index), // seconds
                                            y: .value("BPM", bpm)
                                        )
                                        .foregroundStyle(Color.red.gradient)
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 200)
                                .chartYScale(domain: .automatic(includesZero: false)) // Auto-scale Y axis
                                
                                Text("Did your anxiety drop over time?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // 2. Metrics Summary
                            HStack {
                                StatBox(label: "Peak Body Score", value: "\(Int(sessionManager.calculatePhysiologicalScore(peakBPM: sessionManager.hrReadings.max() ?? 0)))")
                                Divider()
                                StatBox(label: "Peak SUDS", value: "\(Int(subjectiveRating))")
                            }
                            
                            // 3. The Journal
                            VStack(alignment: .leading) {
                                Text("Journal")
                                    .font(.headline)
                                
                                Text("What did you do to cope? (e.g. checked phone, held breath)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                TextField("I relied on...", text: $journalNote)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            Button("Save Session") {
                                saveAndExit()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.large)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(showResults ? "Session Analysis" : "Check-in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showResults { EmptyView() } else { Button("Cancel") { dismiss() } }
                }
            }
            .alert("What is SUDS?", isPresented: $showSUDSHelp) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("Subjective Units of Distress Scale (0-100) measures how intense your anxiety feels.\n0 = Calm, 100 = Panic.")
            }
            .alert("Understanding the Graph", isPresented: $showGraphHelp) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("This graph shows your heart rate over the session. In successful exposure, you want to see the curve go DOWN over time (Habituation).")
            }
        }
    }
    
    // ... (Keep saveAndExit and colorForRating exactly as they were) ...
    // Copy-paste them from your previous file to ensure they exist
    
    func saveAndExit() {
        let peak = sessionManager.hrReadings.max() ?? 0
        let avg = sessionManager.hrReadings.isEmpty ? 0 : sessionManager.hrReadings.reduce(0, +) / Double(sessionManager.hrReadings.count)
        let physScore = sessionManager.calculatePhysiologicalScore(peakBPM: peak)
        
        let newSession = ExposureSession(
            id: UUID(),
            zoneID: zone.id,
            date: Date(),
            duration: sessionManager.currentRuntime,
            peakHR: peak,
            lowestHR: sessionManager.hrReadings.min() ?? 0,
            avgHR: avg,
            stepCount: 0,
            hrReadings: sessionManager.hrReadings,
            subjectiveRating: subjectiveRating,
            physiologicalScore: physScore,
            journalNote: journalNote.isEmpty ? nil : journalNote
        )
        
        SessionDataStore.shared.addSession(newSession)
        
        sessionManager.activeZone = nil
        sessionManager.isSessionActive = false
        
        dismiss()
    }
    
    func colorForRating(_ val: Double) -> Color {
        return val > 70 ? .red : (val > 40 ? .orange : .blue)
    }
}

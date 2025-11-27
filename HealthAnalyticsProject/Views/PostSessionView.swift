import SwiftUI

struct PostSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    
    let zone: ChallengeZone
    
    // User Inputs
    @State private var subjectiveRating: Double = 50
    @State private var journalNote: String = ""
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !showResults {
                    // PHASE 1: The Input
                    Text("How intense was that?")
                        .font(.title2.bold())
                    
                    Text("\(Int(subjectiveRating))/100")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(colorForRating(subjectiveRating))
                    
                    Slider(value: $subjectiveRating, in: 0...100, step: 1)
                        .accentColor(colorForRating(subjectiveRating))
                        .padding()
                    
                    Text("0 = Calm, 100 = Panic")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("See Reality Check") {
                        withAnimation { showResults = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                } else {
                    // PHASE 2: The Reveal
                    ScrollView {
                        VStack(spacing: 25) {
                            // The "Discrepancy" Card
                            RealityCheckCard(
                                userRating: subjectiveRating,
                                bodyScore: sessionManager.calculatePhysiologicalScore(peakBPM: sessionManager.hrReadings.max() ?? 0)
                            )
                            
                            // The Journal
                            VStack(alignment: .leading) {
                                Text("Safety Behavior Check")
                                    .font(.headline)
                                TextField("What did you do to feel safe? (e.g. held phone)", text: $journalNote)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            
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
            .navigationTitle(showResults ? "Session Summary" : "Check-in")
            .toolbar {
                // Prevent accidental dismissal without saving
                ToolbarItem(placement: .cancellationAction) {
                    if showResults { EmptyView() } else { Button("Cancel") { dismiss() } }
                }
            }
        }
    }
    
    // Helper: Save Logic
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
        
        // Reset Manager State
        sessionManager.activeZone = nil
        sessionManager.isSessionActive = false
        
        dismiss()
    }
    
    func colorForRating(_ val: Double) -> Color {
        return val > 70 ? .red : (val > 40 ? .orange : .blue)
    }
}

// Comparison UI Component
struct RealityCheckCard: View {
    let userRating: Double
    let bodyScore: Double
    
    var discrepancy: Double { userRating - bodyScore }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Reality Check")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 30) {
                // Bar 1: Mind
                VStack {
                    Text("\(Int(userRating))")
                        .bold()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 40, height: max(userRating * 1.5, 10))
                    Text("Mind")
                        .font(.caption)
                }
                
                // Bar 2: Body
                VStack {
                    Text("\(Int(bodyScore))")
                        .bold()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 40, height: max(bodyScore * 1.5, 10))
                    Text("Body")
                        .font(.caption)
                }
            }
            
            Divider()
            
            if discrepancy > 10 {
                Text("False Alarm Detected")
                    .font(.title3.bold())
                    .foregroundColor(.green)
                Text("Your fear was **\(Int(discrepancy))%** higher than your actual danger.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            } else {
                Text("In Sync")
                    .font(.title3.bold())
                Text("Your perception matched your body.")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

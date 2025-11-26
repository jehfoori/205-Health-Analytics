import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    // NEW: This allows us to close the screen programmatically
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false
        
    var body: some View {
        // Safely unwrap the optional activeZone
        if let zone = sessionManager.activeZone {
            VStack(spacing: 30) {
                // 1. Header
                VStack(spacing: 5) {
                    Text("EXPOSURE SESSION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(2)
                    Text(zone.name)
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 2. Big Timer
                Text(formatDuration(sessionManager.currentRuntime))
                    .font(.system(size: 70, weight: .thin, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                // 3. Heart Rate Visualizer
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        // Animation note: scaleEffect based on phase can go here later
                    
                    Text("\(Int(sessionManager.currentHeartRate))")
                        .font(.system(size: 60, weight: .bold)) +
                    Text(" BPM")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 4. Stop Button
                Button(action: {
                    showingAlert = true
                }) {
                    Text("End Session")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            // 5. Confirmation Alert
            .alert("End Session?", isPresented: $showingAlert) {
                Button("Resume", role: .cancel) { }
                Button("End & Save", role: .destructive) {
                    // Stop the logic
                    sessionManager.stopSession(for: zone)
                    // CRITICAL FIX: Close the screen
                    dismiss()
                }
            }
        } else {
            // Fallback if something went wrong with state
            VStack {
                Text("No Active Zone Selected")
                Button("Close") { dismiss() }
            }
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00"
    }
}

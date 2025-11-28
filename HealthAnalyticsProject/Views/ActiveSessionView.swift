import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAlert = false
    @State private var showPostSession = false
        
    var body: some View {
        // Changed logic: We unwrap zone, but if it's nil, we check if we are "closing"
        if let zone = sessionManager.activeZone {
            content(for: zone)
        } else {
            // If zone is nil, it means we just finished.
            // Show nothing (or a spinner) while the view dismisses.
            Color.clear.onAppear {
                dismiss()
            }
        }
    }
    
    // Moved the main UI into a helper function to keep the body clean
    func content(for zone: ChallengeZone) -> some View {
        VStack(spacing: 30) {
            // 1. Header
            VStack(spacing: 5) {
                Text("EXPOSURE SESSION")
                    .font(.caption).fontWeight(.bold).foregroundColor(.secondary).tracking(2)
                Text(zone.name)
                    .font(.largeTitle).fontWeight(.black)
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
                
                Text("\(Int(sessionManager.currentHeartRate))")
                    .font(.system(size: 60, weight: .bold)) +
                Text(" BPM").font(.title2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 4. Stop Button
            Button(action: {
                showingAlert = true
            }) {
                Text("End Session")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.red).cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .alert("End Session?", isPresented: $showingAlert) {
            Button("Resume", role: .cancel) { }
            Button("End & Review", role: .destructive) {
                sessionManager.stopSession(for: zone)
                showPostSession = true
            }
        }
        .sheet(isPresented: $showPostSession) {
            PostSessionView(zone: zone)
        }
        // If the manager clears the zone (from PostView), this view will re-render,
        // hit the 'else' block (Color.clear), and call dismiss().
        .onChange(of: sessionManager.activeZone) { newZone in
            if newZone == nil {
                dismiss()
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

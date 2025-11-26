import SwiftUI

struct WatchBreathingView: View {
    @StateObject private var breather = BreathingManager()
    
    var body: some View {
        VStack {
            // 1. Visual Indicator
            ZStack {
                Circle()
                    .fill(colorForPhase(breather.phaseColor))
                    .opacity(0.3)
                    .animation(.easeInOut(duration: 4.0), value: breather.phaseColor)
                
                Text(breather.phaseText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .transition(.opacity)
                    .id("Text" + breather.phaseText) // Forces redraw for animation
            }
            .frame(height: 100)
            
            Spacer()
            
            // 2. The SOS Button
            Button(action: {
                // Trigger Haptics
                breather.toggleBreathing()
            }) {
                Text(breather.isActive ? "Stop" : "SOS / Breathe")
                    .foregroundColor(breather.isActive ? .red : .white)
            }
            .buttonStyle(.borderedProminent)
            .tint(breather.isActive ? .gray : .blue)
        }
        .padding()
    }
    
    // Helper to convert string to Color
    func colorForPhase(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
}

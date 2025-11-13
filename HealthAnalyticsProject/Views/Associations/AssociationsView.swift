import SwiftUI

struct AssociationsView: View {
    let todayEvents = MockData.todayEvents
    let patterns = MockData.behaviorPatterns
    let insights = MockData.associations   // your old “top signals”
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("How your digital behavior links to physiology.")
                    .foregroundColor(.secondary)
                
                // 1. TODAY
                GroupBox("Today's notable events") {
                    if todayEvents.isEmpty {
                        Text("No notable digital–physiology events detected today.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(todayEvents) { ev in
                                HStack(alignment: .top, spacing: 10) {
                                    
                                    severityDot(ev.severity)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(ev.time) — \(ev.title)")
                                            .bold()
                                        Text(ev.note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                if ev.id != todayEvents.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                // 3. OVERALL STATS
                GroupBox("General statistical associations") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(insights) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(color(for: i.direction).opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: i.direction == .stressor ? "heart.slash" : "heart.text.square")
                                            .foregroundColor(color(for: i.direction))
                                    )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(i.title).bold()
                                    Text(i.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("corr = \(String(format: "%.2f", i.corr))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            if i.id != insights.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                
                Spacer().frame(height: 30)
            }
            .padding()
        }
        .navigationTitle("Associations")
    }
    
    // MARK: - helpers
    
    private func color(for dir: AssociationDirection) -> Color {
        switch dir {
        case .stressor: return .red
        case .helper:   return .green
        }
    }
    
    private func severityDot(_ s: TodayEventSeverity) -> some View {
        let color: Color
        let icon: String
        
        switch s {
        case .low:
            color = .gray
            icon = "dot.radiowaves.left.and.right"
        case .med:
            color = .orange
            icon = "exclamationmark.circle"
        case .high:
            color = .red
            icon = "flame"
        }
        
        return Circle()
            .fill(color.opacity(0.15))
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: icon)
                    .foregroundColor(color)
            )
    }
    
    
    private func strengthPill(_ s: String) -> some View {
        let color: Color
        switch s {
        case "consistent": color = .green
        case "emerging":   color = .blue
        case "weak":       color = .gray
        default:           color = .gray
        }
        
        return Text(s.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


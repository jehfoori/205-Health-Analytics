import SwiftUI

struct ScreenTimeCard: View {
    let apps: [AppUsageStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Screen time")
                    .font(.headline)
                Spacer()
                Text("See all")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(apps) { app in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.appName).bold()
                        Text(app.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(app.minutesToday)m")
                        .bold()
                    trendIcon(app.trend)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func trendIcon(_ trend: UsageTrend) -> some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up.right")
                .foregroundColor(.red)
        case .down:
            Image(systemName: "arrow.down.right")
                .foregroundColor(.green)
        case .flat:
            Image(systemName: "minus")
                .foregroundColor(.secondary)
        }
    }
}

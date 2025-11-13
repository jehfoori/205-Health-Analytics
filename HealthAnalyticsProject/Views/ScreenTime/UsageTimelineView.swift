import SwiftUI

struct UsageTimelineView: View {
    /// raw intervals during the day
    let intervals: [UsageInterval]
    /// show “0h 12h 24h”
    var showLabels: Bool = true

    var body: some View {
        let buckets = makeHourlyBuckets(from: intervals)

        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let h = geo.size.height
                let w = geo.size.width
                let maxVal = max(buckets.map { $0.usageMinutes }.max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(buckets) { bucket in
                        let ratio = CGFloat(bucket.usageMinutes) / CGFloat(maxVal)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color(for: bucket.hour))
                            .frame(
                                width: (w / 24) - 2,
                                height: max(ratio * (h - 4), 2)
                            )
                            .opacity(bucket.usageMinutes == 0 ? 0.18 : 0.95)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(height: 60)

            if showLabels {
                HStack {
                    Text("0h").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("12h").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("24h").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Bucketing

    private func makeHourlyBuckets(from intervals: [UsageInterval]) -> [UsageBucket] {
        // if nothing was passed, fake “evening heavy” so the UI isn’t empty
        if intervals.isEmpty {
            return (0..<24).map { hour in
                let usage: Int
                switch hour {
                case 21, 22, 23: usage = Int.random(in: 10...25)
                case 12, 13:     usage = Int.random(in: 5...12)
                default:         usage = Int.random(in: 0...4)
                }
                return UsageBucket(id: hour, hour: hour, usageMinutes: usage)
            }
        }

        // real path: sum minutes per hour
        var dict: [Int: Int] = [:]  // hour -> minutes
        let cal = Calendar.current

        for interval in intervals {
            let startHour = cal.component(.hour, from: interval.start)
            // assume everything in same hour for mock
            dict[startHour, default: 0] += interval.minutes
        }

        return (0..<24).map { hour in
            UsageBucket(id: hour, hour: hour, usageMinutes: dict[hour] ?? 0)
        }
    }

    private func color(for hour: Int) -> Color {
        // make evening a bit warmer
        if hour >= 20 {
            return .pink
        } else if hour >= 12 {
            return .blue
        } else {
            return .teal
        }
    }
}

// helper model
struct UsageBucket: Identifiable {
    let id: Int
    let hour: Int
    let usageMinutes: Int
}

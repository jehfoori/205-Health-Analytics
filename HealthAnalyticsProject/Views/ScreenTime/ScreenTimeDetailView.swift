import SwiftUI

struct ScreenTimeDetailView: View {
    let apps = MockData.topAppsToday
    @State private var usageMode: UsageMode = .overall   // overall vs per-app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Today's Usage Data")
                    .font(.title2).bold()

                // TOP APPS TABLE
                GroupBox {
                    VStack(spacing: 10) {
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
                                trendIcon(app.trend)
                            }
                            Divider()
                        }
                    }
                }

                // MODE PICKER
                Picker("View", selection: $usageMode) {
                    Text("Overall").tag(UsageMode.overall)
                    Text("By app").tag(UsageMode.byApp)
                }
                .pickerStyle(.segmented)

                // TIMELINE AREA
                Group {
                    switch usageMode {
                    case .overall:
                        GroupBox("Timeline — all apps (mock)") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Distribution across the day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                UsageTimelineView(intervals: MockData.usageTimelineToday)
                                    .frame(height: 80)

                                Text("Evening usage is the heaviest.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                    case .byApp:
                        GroupBox("Timeline — by app (mock)") {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(apps) { app in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(app.appName).bold()
                                            Spacer()
                                            Text("\(app.minutesToday)m today")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        // filter the intervals for this app
                                        let intervals = MockData.usageTimelineToday.filter { $0.appName == app.appName }

                                        if intervals.isEmpty {
                                            Text("No specific sessions today.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            UsageTimelineView(intervals: intervals, showLabels: false)
                                                .frame(height: 32)
                                        }
                                    }
                                    if app.id != apps.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding()
        }
        .navigationTitle("Screen time")
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

    enum UsageMode {
        case overall
        case byApp
    }
}

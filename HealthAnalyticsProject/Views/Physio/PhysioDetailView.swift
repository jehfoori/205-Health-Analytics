import SwiftUI

struct PhysioDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Physiological data")
                    .font(.title2).bold()

                GroupBox("Today — HRV") {
                    HRVMiniChart(data: MockData.physiologicalToday.map { ($0.time, $0.hrv) })
                        .frame(height: 140)
                }

                GroupBox("Today — Heart rate") {
                    HStack(spacing: 8) {
                        ForEach(MockData.physiologicalToday) { p in
                            VStack {
                                Text("\(p.heartRate)")
                                    .font(.headline)
                                Text(shortTime(p.time))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                GroupBox("Last 7 days — HRV avg") {
                    HRVMiniChart(data: MockData.physiologicalDaily.map { ($0.date, $0.avgHRV) })
                        .frame(height: 140)
                }

                GroupBox("Notes (mock)") {
                    Text("Lower HRV on 2 days with late-night social usage. Slight recovery on Sunday.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer().frame(height: 30)
            }
            .padding()
        }
        .navigationTitle("Physiology")
    }

    private func shortTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "ha"
        return f.string(from: d)
    }
}

struct HRVMiniChart: View {
    let data: [(date: Date, value: Double)]

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)

            ZStack {
                // Fill
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                        for p in points {
                            path.addLine(to: p)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }

                // Stroke
                Path { path in
                    if let first = points.first {
                        path.move(to: first)
                        for p in points.dropFirst() {
                            path.addLine(to: p)
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)

                // Baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height - 1))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 1))
                }
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            }
        }
        .frame(height: 120)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let maxVal = max(data.map { $0.value }.max() ?? 1, 1)
        let minVal = data.map { $0.value }.min() ?? 0
        let span = max(maxVal - minVal, 1)

        let stepX = size.width / CGFloat(max(data.count - 1, 1))

        return data.enumerated().map { idx, point in
            let x = CGFloat(idx) * stepX
            // higher HRV → higher on screen => invert y
            let norm = (point.value - minVal) / span
            let y = size.height - (CGFloat(norm) * size.height * 0.85) - 6
            return CGPoint(x: x, y: y)
        }
    }
}

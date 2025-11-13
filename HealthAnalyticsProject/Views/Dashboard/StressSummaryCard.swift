import SwiftUI

struct StressSummaryCard: View {
    let score: Int           // 0–100
    let label: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today’s stress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.title3).bold()
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack {
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("of 100")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

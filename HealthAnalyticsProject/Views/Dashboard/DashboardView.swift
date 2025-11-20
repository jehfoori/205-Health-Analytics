import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overview")
                        .foregroundColor(.secondary)
                }
                // physio (clickable)
                NavigationLink {
                    PhysioDetailView()
                } label: {
                    StressSummaryCard(
                        score: MockData.physioStressScore,
                        label: MockData.physioStressLabel,
                        subtitle: MockData.physioStressSubtitle
                    )
                }
                .buttonStyle(.plain)

                // screen time (clickable)
                NavigationLink {
                    ScreenTimeDetailView()
                } label: {
                    ScreenTimeCard(apps: Array(MockData.topAppsToday.prefix(3)))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

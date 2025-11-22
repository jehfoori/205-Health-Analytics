import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = StepCountViewModel()
    private let sedentaryLocationManager = SedentaryLocationManager.shared

    var body: some View {
        TabView {
            // MARK: - Today Tab
            NavigationView {
                VStack(spacing: 20) {
                    // Map at the top
                    CurrentLocationMapView()
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    // Status
                    Text(viewModel.statusMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Steps
                    Text("\(viewModel.stepCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("Today’s steps")

                    // HRV
                    VStack(spacing: 4) {
                        Text(viewModel.hrvDisplayText)
                            .font(.title2.bold())
                        Text("HRV (SDNN, ms)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Latest heart rate
                    VStack(spacing: 4) {
                        Text(viewModel.heartRateDisplayText)
                            .font(.title3.bold())
                        Text("Most recent heart rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Latest location
                    Text(viewModel.locationDisplayText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Refresh button
                    Button(action: {
                        viewModel.refreshAll()
                    }) {
                        Text("Refresh Data Now")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Today's Steps")
                .onAppear {
                    // Request HealthKit + start location tracking when this tab appears
                    viewModel.requestHealthKitAccess()
                    sedentaryLocationManager.start()
                }
            }
            .tabItem {
                Label("Today", systemImage: "figure.walk")
            }

            // MARK: - Dashboard Tab
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            // MARK: - Associations Tab
            NavigationView {
                AssociationsView()
            }
            .tabItem {
                Label("Associations", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }

            // MARK: - Settings / Profile Tab
            NavigationView {
                Text("Settings / Profile (mock)")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Me", systemImage: "person.crop.circle")
            }
        }
    }
}

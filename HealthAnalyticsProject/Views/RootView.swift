import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = StepCountViewModel()
    private let sedentaryLocationManager = SedentaryLocationManager.shared
    var body: some View {
        TabView {
            NavigationView {
<<<<<<< Updated upstream
                        VStack(spacing: 20) {
                            CurrentLocationMapView()
                                .frame(height: 250)   // adjust height to taste
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            
                            Text(viewModel.statusMessage)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("\(viewModel.stepCount)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            
                            Button(action: {
                                viewModel.refreshStepCount()
                            }) {
                                Text("Refresh Steps")
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
=======
                VStack(spacing: 16) {
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

                    Button(action: {
                        viewModel.refreshAll()   // this now pulls HRV + HR + location too
                    }) {
                        Text("Refresh Data Now")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Spacer()
                }

>>>>>>> Stashed changes
                        .padding()
                        .navigationTitle("Today's Steps")
                        .onAppear {
                            // Request HealthKit access once the view is on screen and app is active
                            viewModel.requestHealthKitAccess()
                            sedentaryLocationManager.start()
                        }
                    }
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            NavigationView {
                AssociationsView()
            }
            .tabItem {
                Label("Associations", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }

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

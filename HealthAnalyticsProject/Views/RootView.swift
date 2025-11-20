import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = StepCountViewModel()
    private let sedentaryLocationManager = SedentaryLocationManager.shared
    var body: some View {
        TabView {
            NavigationView {
                        VStack(spacing: 20) {
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

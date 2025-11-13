import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
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

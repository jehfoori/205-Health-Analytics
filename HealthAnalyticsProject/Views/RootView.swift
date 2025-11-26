import SwiftUI

struct RootView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        TabView {
            ZoneMapView()
                .environmentObject(sessionManager)
                .tabItem { Label("Explore", systemImage: "map") }
            
            // REPLACE THE PLACEHOLDER WITH THIS:
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
        }
    }
}

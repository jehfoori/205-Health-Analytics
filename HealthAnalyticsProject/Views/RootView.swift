import SwiftUI

struct RootView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        TabView {
            ZoneMapView()
                .environmentObject(sessionManager)
                .tabItem { Label("Explore", systemImage: "map") }
            
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
            
            // NEW TAB
            LearningView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
        }
    }
}

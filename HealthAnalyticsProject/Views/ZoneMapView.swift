import SwiftUI
import MapKit

struct ZoneMapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var dataStore = ZoneDataStore.shared
    @EnvironmentObject var sessionManager: SessionManager // Access the manager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var isNamingZone = false
    @State private var newZoneName = ""
    
    // NEW: State to track which zone is selected
    @State private var selectedZone: ChallengeZone?
    @State private var showSessionScreen = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: dataStore.zones) { zone in
                MapAnnotation(coordinate: zone.coordinate) {
                    // Make the pin clickable
                    Button(action: {
                        selectedZone = zone
                    }) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .foregroundColor(.red)
                                .frame(width: 30, height: 30)
                                .background(Color.white.clipShape(Circle()))
                            Text(zone.name)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            // ... (Keep the "Targeting" Pin and "Add Zone" logic exactly the same) ...
            // (Copy the previous VStack/Controls logic here)
            // For brevity, I'm assuming you keep the existing UI code for the targeting pin/buttons
            VStack {
                Spacer()
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .shadow(radius: 2)
                Spacer()
            }
            .allowsHitTesting(false)
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        if let loc = locationManager.currentLocation {
                            withAnimation { region.center = loc.coordinate }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    Spacer()
                    Button(action: { isNamingZone = true }) {
                        Text("Add Zone Here")
                            .bold() .padding() .background(Color.blue) .foregroundColor(.white) .cornerRadius(10) .shadow(radius: 4)
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear { locationManager.start() }
        .alert("Name this Location", isPresented: $isNamingZone) {
            TextField("e.g. Grocery Store", text: $newZoneName)
            Button("Save") {
                dataStore.addZone(name: newZoneName, latitude: region.center.latitude, longitude: region.center.longitude)
                newZoneName = ""
            }
            Button("Cancel", role: .cancel) { }
        }
        // ... inside ZoneMapView body ...
        
        // 1. The Sheet (Pre-flight check)
        .sheet(item: $selectedZone) { zone in
            VStack(spacing: 20) {
                Text(zone.name).font(.title).bold()
                Text("Are you ready to start exposure therapy here?")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Start Session") {
                    // CRITICAL STEP: Tell the manager WHICH zone we are doing
                    sessionManager.activeZone = zone
                    sessionManager.startSession()
                    
                    // Close the sheet
                    selectedZone = nil
                    // Open the full screen cover
                    showSessionScreen = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .presentationDetents([.medium])
        }
        // 2. The Full Screen Cover (The Workout)
        .fullScreenCover(isPresented: $showSessionScreen) {
            // ERROR FIX: Do not pass arguments here.
            ActiveSessionView()
        }
    }
}

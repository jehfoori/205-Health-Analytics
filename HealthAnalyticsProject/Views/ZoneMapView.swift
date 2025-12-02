import SwiftUI
import MapKit
import CoreLocation

struct ZoneMapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var dataStore = ZoneDataStore.shared
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var isNamingZone = false
    @State private var newZoneName = ""
    
    @State private var selectedZone: ChallengeZone?
    @State private var showSessionScreen = false
    
    // NEW: Info Sheet state
    @State private var showInfoSheet = false
    
    private let allowedRadiusMeters: CLLocationDistance = 0.2 * 1609.34  // ~321.9 m

    private func isWithinAllowedRadius(of zone: ChallengeZone) -> Bool {
        guard let userLocation = locationManager.currentLocation else {
            return false
        }

        let zoneLocation = CLLocation(latitude: zone.latitude,
                                      longitude: zone.longitude)
        let distance = userLocation.distance(from: zoneLocation) // meters
        return distance <= allowedRadiusMeters
    }

    private func distanceToZoneMiles(_ zone: ChallengeZone) -> Double? {
        guard let userLocation = locationManager.currentLocation else {
            return nil
        }

        let zoneLocation = CLLocation(latitude: zone.latitude,
                                      longitude: zone.longitude)
        let distanceMeters = userLocation.distance(from: zoneLocation)
        return distanceMeters / 1609.34   // meters → miles
    }

    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: dataStore.zones) { zone in
                MapAnnotation(coordinate: zone.coordinate) {
                    Button(action: { selectedZone = zone }) {
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
            
            // Targeting Pin
            VStack {
                Spacer()
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .shadow(radius: 2)
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Controls Overlay
            VStack {
                // NEW: Header with Info Button
                HStack {
                    Spacer()
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.trailing)
                }
                
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
                            .bold()
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 4)
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
        .sheet(item: $selectedZone) { zone in
            VStack(spacing: 20) {
                Text(zone.name).font(.title).bold()
                Text("Ready for the session?")
                    .multilineTextAlignment(.center)

                Button {
                    // Start Exposure Session
                    sessionManager.activeZone = zone
                    sessionManager.startSession()
                    selectedZone = nil
                    showSessionScreen = true
                } label: {
                    VStack(spacing: 4) {
                        Text(isWithinAllowedRadius(of: zone)
                             ? "Start Exposure Here"
                             : "Move closer to this zone")
                            .font(.headline)

                        if let distanceMiles = distanceToZoneMiles(zone) {
                            Text(String(format: "%.2f miles from zone", distanceMiles))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Waiting for GPS…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(!isWithinAllowedRadius(of: zone))
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .presentationDetents([.medium])
        }

        .fullScreenCover(isPresented: $showSessionScreen) {
            ActiveSessionView()
        }
        // NEW: The Psychoeducation Sheet
        .sheet(isPresented: $showInfoSheet) {
            VStack(spacing: 20) {
                Text("How Exposure Therapy Works")
                    .font(.title2.bold())
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .foregroundColor(.blue)
                        Text("**Habituation:** If you stay in a scary situation long enough without leaving, your anxiety will eventually go down naturally.")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("**Retraining:** This app helps you prove to your brain that these places are safe, even if they feel uncomfortable.")
                    }
                }
                .padding()
                
                Button("Got it") { showInfoSheet = false }
                    .buttonStyle(.bordered)
            }
            .presentationDetents([.medium])
        }
    }
}

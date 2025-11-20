import SwiftUI
import MapKit
import CoreLocation

struct CurrentLocationMapView: View {
    @ObservedObject private var locationManager = SedentaryLocationManager.shared

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452), // fallback (e.g., UCLA)
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            // Fill the available space wherever you place it
            .onAppear {
                // Make sure location tracking is running
                locationManager.start()

                // Center immediately if we already have a location
                if let loc = locationManager.currentLocation {
                    region.center = loc.coordinate
                }
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                guard let coord = newLocation?.coordinate else { return }
                // Follow the user as they move
                region.center = coord
            }
    }
}

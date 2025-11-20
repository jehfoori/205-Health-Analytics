import Foundation
import CoreData
import CoreLocation

struct HeartRateLocationSample: Identifiable {
    let id: NSManagedObjectID
    let timestamp: Date?
    let bpm: Double
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

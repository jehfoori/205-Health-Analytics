import Foundation
import CoreLocation

// 1. The Place you want to conquer
struct ChallengeZone: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double // In meters, e.g., 50m
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// 2. The Record of a specific attempt
struct ExposureSession: Identifiable, Codable {
    let id: UUID
    let zoneID: UUID
    let date: Date
    let duration: TimeInterval
    
    // Metrics
    let peakHR: Double
    let lowestHR: Double
    let avgHR: Double
    let stepCount: Int
    
    // This is the graph data
    let hrReadings: [Double]
}

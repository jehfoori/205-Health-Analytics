//
//  HeartRateLocationStore.swift
//  HealthAnalyticsProject
//
//  Created by Aaron Zhao on 11/19/25.
//

import Foundation
import CoreData
import CoreLocation

final class HeartRateLocationStore: ObservableObject {
    static let shared = HeartRateLocationStore()

    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext {
        container.viewContext
    }

    @Published private(set) var samples: [HeartRateLocationSample] = []

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        loadRecentSamples()
    }

    // MARK: - Public API

    func addSample(bpm: Double, location: CLLocation, at timestamp: Date) {
        context.perform {
            let entity = HeartRateLocationSampleEntity(context: self.context)
            entity.timestamp = timestamp
            entity.bpm = bpm
            entity.latitude = location.coordinate.latitude
            entity.longitude = location.coordinate.longitude
            entity.horizontalAccuracy = location.horizontalAccuracy

            do {
                try self.context.save()
                self.loadRecentSamples()
            } catch {
                print("Error saving HR+Location sample:", error)
            }
        }
    }

    /// Fetch samples in the last `days` days (default: 7)
    func loadRecentSamples(lastDays days: Int = 7) {
        context.perform {
            let request: NSFetchRequest<HeartRateLocationSampleEntity> = HeartRateLocationSampleEntity.fetchRequest()

            let now = Date()
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? .distantPast
            request.predicate = NSPredicate(format: "timestamp >= %@", cutoff as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let models = entities.map { $0.toModel() }
                DispatchQueue.main.async {
                    self.samples = models
                }
            } catch {
                print("Error fetching HR+Location samples:", error)
            }
        }
    }
}

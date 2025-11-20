//
//  DailyMetricsModel.swift
//  HealthAnalyticsProject
//
//  Created by Aaron Zhao on 11/19/25.
//


import Foundation
import CoreData

// MARK: - Domain Models (what your view models will use)

struct DailyMetricsModel: Identifiable {
    let id = UUID()
    let date: Date               // normalized to startOfDay
    let steps: Int
    let averageHRV: Double?
    let averageHeartRate: Double?
    let sedentaryMinutes: Int
}

struct LocationEventModel: Identifiable {
    let id = UUID()
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
}

struct SedentaryEpisodeModel: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date?
}

// MARK: - AnalyticsStore Protocol

protocol AnalyticsStore {
    // Location / sedentary
    func saveLocationEvent(lat: Double,
                           lon: Double,
                           accuracy: Double,
                           at timestamp: Date) throws

    func startSedentaryEpisode(at date: Date) throws
    func endCurrentSedentaryEpisode(at date: Date) throws

    // Daily summaries (steps, HRV, HR, sedentary minutes)
    func upsertDailyMetrics(_ metrics: DailyMetricsModel) throws
    func fetchDailyMetrics(from startDate: Date,
                           to endDate: Date) throws -> [DailyMetricsModel]

    // Optional helpers
    func fetchLocationEvents(from startDate: Date,
                             to endDate: Date) throws -> [LocationEventModel]
}

// MARK: - Core Data Stack

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // IMPORTANT: this must match the name of your .xcdatamodeld file
        container = NSPersistentContainer(name: "HealthAnalyticsModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - CoreDataAnalyticsStore Implementation

final class CoreDataAnalyticsStore: AnalyticsStore {
    private let container: NSPersistentContainer

    private var context: NSManagedObjectContext {
        container.viewContext
    }

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: Location / Sedentary

    func saveLocationEvent(lat: Double,
                           lon: Double,
                           accuracy: Double,
                           at timestamp: Date) throws {
        try context.performAndWait {
            let event = LocationEventEntity(context: context)
            event.timestamp = timestamp
            event.latitude = lat
            event.longitude = lon
            event.horizontalAccuracy = accuracy
            try context.save()
        }
    }

    func startSedentaryEpisode(at date: Date) throws {
        try context.performAndWait {
            // Close any existing open episode, just in case
            let fetch: NSFetchRequest<SedimentaryEpisodeEntity> = SedentaryEpisodeEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "end == nil")
            let openEpisodes = try context.fetch(fetch)
            for ep in openEpisodes {
                ep.end = date
            }

            let episode = SedentaryEpisodeEntity(context: context)
            episode.start = date
            episode.end = nil

            try context.save()
        }
    }

    func endCurrentSedentaryEpisode(at date: Date) throws {
        try context.performAndWait {
            let fetch: NSFetchRequest<SedentaryEpisodeEntity> = SedentaryEpisodeEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "end == nil")
            fetch.fetchLimit = 1

            if let open = try context.fetch(fetch).first {
                open.end = date
                try context.save()
            }
        }
    }

    // MARK: Daily Metrics

    func upsertDailyMetrics(_ metrics: DailyMetricsModel) throws {
        try context.performAndWait {
            let day = startOfDay(for: metrics.date)

            let fetch: NSFetchRequest<DailyMetricsEntity> = DailyMetricsEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "date == %@", day as NSDate)
            fetch.fetchLimit = 1

            let entity: DailyMetricsEntity
            if let existing = try context.fetch(fetch).first {
                entity = existing
            } else {
                entity = DailyMetricsEntity(context: context)
                entity.date = day
            }

            entity.steps = Int64(metrics.steps)
            entity.averageHRV = metrics.averageHRV as NSNumber?
            entity.averageHeartRate = metrics.averageHeartRate as NSNumber?
            entity.sedentaryMinutes = Int32(metrics.sedentaryMinutes)

            try context.save()
        }
    }

    func fetchDailyMetrics(from startDate: Date,
                           to endDate: Date) throws -> [DailyMetricsModel] {
        try context.performAndWait {
            let fetch: NSFetchRequest<DailyMetricsEntity> = DailyMetricsEntity.fetchRequest()
            fetch.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                startOfDay(for: startDate) as NSDate,
                startOfDay(for: endDate) as NSDate
            )
            fetch.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            let entities = try context.fetch(fetch)
            return entities.map { $0.toModel() }
        }
    }

    func fetchLocationEvents(from startDate: Date,
                             to endDate: Date) throws -> [LocationEventModel] {
        try context.performAndWait {
            let fetch: NSFetchRequest<LocationEventEntity> = LocationEventEntity.fetchRequest()
            fetch.predicate = NSPredicate(
                format: "timestamp >= %@ AND timestamp <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

            let entities = try context.fetch(fetch)
            return entities.map { $0.toModel() }
        }
    }

    // MARK: - Helpers

    private func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

// MARK: - Core Data Entity Classes

@objc(DailyMetricsEntity)
class DailyMetricsEntity: NSManagedObject {
    @NSManaged var date: Date
    @NSManaged var steps: Int64
    @NSManaged var averageHRV: NSNumber?         // stored as NSNumber to keep optional Double
    @NSManaged var averageHeartRate: NSNumber?
    @NSManaged var sedentaryMinutes: Int32
}

extension DailyMetricsEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DailyMetricsEntity> {
        NSFetchRequest<DailyMetricsEntity>(entityName: "DailyMetricsEntity")
    }

    func toModel() -> DailyMetricsModel {
        DailyMetricsModel(
            date: date,
            steps: Int(steps),
            averageHRV: averageHRV?.doubleValue,
            averageHeartRate: averageHeartRate?.doubleValue,
            sedentaryMinutes: Int(sedentaryMinutes)
        )
    }
}

@objc(LocationEventEntity)
class LocationEventEntity: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var horizontalAccuracy: Double
}

extension LocationEventEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LocationEventEntity> {
        NSFetchRequest<LocationEventEntity>(entityName: "LocationEventEntity")
    }

    func toModel() -> LocationEventModel {
        LocationEventModel(
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: horizontalAccuracy
        )
    }
}

@objc(SedentaryEpisodeEntity)
class SedentaryEpisodeEntity: NSManagedObject {
    @NSManaged var start: Date
    @NSManaged var end: Date?
}

extension SedentaryEpisodeEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SedentaryEpisodeEntity> {
        NSFetchRequest<SedentaryEpisodeEntity>(entityName: "SedentaryEpisodeEntity")
    }

    func toModel() -> SedentaryEpisodeModel {
        SedentaryEpisodeModel(start: start, end: end)
    }
}

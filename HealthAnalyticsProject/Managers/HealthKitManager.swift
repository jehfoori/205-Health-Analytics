import SwiftUI
import HealthKit
import Combine

final class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // We keep a reference to the active observer query so it doesn't get deallocated
    private var observerQuery: HKObserverQuery?
    
    private init() {}
    
    // MARK: - Permissions & Setup
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            guard HKHealthStore.isHealthDataAvailable() else {
                completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data unavailable"]))
                return
            }
            
            guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
                  let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
                  let hrType  = HKObjectType.quantityType(forIdentifier: .heartRate),
                  let restingType = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
                  let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
                completion(false, NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Types unavailable"]))
                return
            }
            
            let readTypes: Set<HKObjectType> = [stepType, hrvType, hrType, restingType, dobType]
            
            self.healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if success {
                    // CRITICAL: Once authorized, we enable background delivery immediately.
                    // This tells iOS: "We want updates for Heart Rate as soon as they happen."
                    self.enableBackgroundDelivery(for: hrType)
                }
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
    
    /// Tells the system to prioritize syncing this data type
    private func enableBackgroundDelivery(for type: HKObjectType) {
        guard let sampleType = type as? HKSampleType else { return }
        
        // .immediate is the highest frequency.
        // Note: iOS may still throttle this depending on battery/thermal state,
        // but it is the strongest request we can make.
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            } else {
                print("Background delivery enabled for \(sampleType.identifier)")
            }
        }
    }
    
    // MARK: - Observer Query (The "Push" Mechanism)
    
    /// Starts observing Heart Rate.
    /// - Parameter onUpdate: A closure called whenever NEW data arrives in the DB.
    func startObservingHeartRate(onUpdate: @escaping () -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Stop any existing query to be safe
        if let existing = observerQuery {
            healthStore.stop(existing)
        }
        
        let query = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Observer Error: \(error.localizedDescription)")
                return
            }
            
            // This block runs whenever HealthKit receives new data (e.g. from Watch sync)
            // We notify the caller (SessionManager) to go fetch the data.
            onUpdate()
            
            // We must call this to signal we handled the background event
            completionHandler()
        }
        
        self.observerQuery = query
        healthStore.execute(query)
        print("Observer Query Started for Heart Rate")
    }
    
    func stopObservingHeartRate() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
            print("Observer Query Stopped")
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchMostRecentHeartRate(completion: @escaping (Double?, Date?, Error?) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        // Look for samples in the last 60 seconds
        let start = Date().addingTimeInterval(-60)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, samples, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil, nil, error) }
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil, nil, nil) }
                return
            }

            let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let bpm = sample.quantity.doubleValue(for: unit)
            let timestamp = sample.startDate

            DispatchQueue.main.async {
                completion(bpm, timestamp, nil)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchRestingHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async { completion(bpm, nil) }
        }
        healthStore.execute(query)
    }
    
    func fetchUserAge(completion: @escaping (Int?, Error?) -> Void) {
        do {
            let components = try healthStore.dateOfBirthComponents()
            let age = Calendar.current.dateComponents([.year], from: components.date!, to: Date()).year
            DispatchQueue.main.async { completion(age, nil) }
        } catch {
            DispatchQueue.main.async { completion(nil, error) }
        }
    }
}

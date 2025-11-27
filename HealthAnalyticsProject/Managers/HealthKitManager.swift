import SwiftUI
import HealthKit
import Combine

// MARK: - HealthKit Manager

final class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // Request authorization to read step count
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Must be on main thread for the system sheet to appear correctly
        precondition(Thread.isMainThread, "requestAuthorization must be called on the main thread")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(
                domain: "HealthKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Health data not available on this device."]
            )
            completion(false, error)
            return
        }
        
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let hrType  = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            let error = NSError(
                domain: "HealthKit",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Required HealthKit types are unavailable."]
            )
            completion(false, error)
            return
        }
        guard let restingType = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
            // handle error
            return
        }
        
        let readTypes: Set<HKObjectType> = [stepType, hrvType, hrType, restingType, dobType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
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

    
    // Fetch today's total step count
    func fetchTodayStepCount(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = NSError(
                domain: "HealthKit",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Step Count type is unavailable."]
            )
            completion(nil, error)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let totalSteps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
            
            DispatchQueue.main.async {
                completion(totalSteps, nil)
            }
        }
        
        healthStore.execute(query)
    }
    // Fetch today's average HRV (SDNN) in milliseconds
    func fetchTodayHRV(completion: @escaping (Double?, Error?) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            let error = NSError(
                domain: "HealthKit",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "HRV type is unavailable."]
            )
            completion(nil, error)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: now)!
        let startOfDay = calendar.startOfDay(for: eightDaysAgo)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, statistics, error in
            
            // 1) Explicitly treat "no data" as a non-error
            if let hkError = error as? HKError, hkError.code == .errorNoData {
                DispatchQueue.main.async {
                    completion(nil, nil)   // means "no HRV today"
                }
                return
            }
            
            // 2) Any other real error
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // 3) No error, but also no samples -> also "no data"
            let unit = HKUnit.secondUnit(with: .milli)
            let averageHRVms = statistics?.averageQuantity()?.doubleValue(for: unit)
            
            DispatchQueue.main.async {
                // If averageHRVms is nil, we just send nil to mean "no data"
                completion(averageHRVms, nil)
            }
        }
        
        healthStore.execute(query)
    }
    // Most recent heart rate sample (bpm) and its timestamp
    func fetchMostRecentHeartRate(completion: @escaping (Double?, Date?, Error?) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            let error = NSError(
                domain: "HealthKit",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Heart rate type is unavailable."]
            )
            completion(nil, nil, error)
            return
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: [])

        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, samples, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, nil, error)
                }
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                // No HR data at all
                DispatchQueue.main.async {
                    completion(nil, nil, nil)
                }
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


}

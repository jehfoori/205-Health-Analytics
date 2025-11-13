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
        
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = NSError(
                domain: "HealthKit",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Step Count type is unavailable."]
            )
            completion(false, error)
            return
        }
        
        let readTypes: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
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
}

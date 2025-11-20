import SwiftUI
import HealthKit
import Combine

// MARK: - ViewModel
final class StepCountViewModel: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var statusMessage: String = "Requesting HealthKit access…"
    
    private let healthKitManager = HealthKitManager.shared
    
    init() {
        
    }
    
    func requestHealthKitAccess() {
        // Ensure we're on the main thread when calling requestAuthorization
        DispatchQueue.main.async {
            self.healthKitManager.requestAuthorization { [weak self] success, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.statusMessage = "Authorization error: \(error.localizedDescription)"
                    return
                }
                
                if success {
                    self.statusMessage = "Authorized. Fetching steps…"
                    self.refreshStepCount()
                } else {
                    self.statusMessage = "HealthKit authorization was not granted."
                }
            }
        }
    }
    
    func refreshStepCount() {
        healthKitManager.fetchTodayStepCount { [weak self] steps, error in
            guard let self = self else { return }
            
            if let error = error {
                self.statusMessage = "Error fetching steps: \(error.localizedDescription)"
                return
            }
            
            if let steps = steps {
                self.stepCount = Int(steps)
                self.statusMessage = "Today's steps:"
            } else {
                self.statusMessage = "No step data available."
            }
        }
    }
}

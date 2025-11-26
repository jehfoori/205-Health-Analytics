import Foundation
import WatchKit
import HealthKit
import Combine

class BreathingManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    @Published var phaseText: String = "Tap to Start"
    @Published var isActive: Bool = false
    @Published var phaseColor: String = "gray"
    
    private var timer: Timer?
    private var cycleStep = 0
    private let stepDuration: TimeInterval = 4.0
    
    // HEALTHKIT SESSION VARS
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    override init() {
        super.init()
        requestAuthorization() // <--- Add this!
    }
    
    private func requestAuthorization() {
        // We need to WRITE workouts and READ heart rate
        let typesToShare: Set = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Authorization request finished.
            // Note: 'success' true just means the SHEET was shown, not that they clicked Allow.
            if let error = error {
                print("Auth Error: \(error.localizedDescription)")
            } else {
                print("Auth request complete.")
            }
        }
    }
    
    func toggleBreathing() {
        if isActive {
            stop()
        } else {
            start()
        }
    }
    
    private func start() {
        isActive = true
        cycleStep = 0
        
        // 1. Start the visual/haptic cycle
        runCycle()
        timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] _ in
            self?.cycleStep += 1
            if self?.cycleStep ?? 0 > 2 { self?.cycleStep = 0 }
            self?.runCycle()
        }
        
        // 2. Start the HealthKit Workout (Keeps app alive)
        startWorkoutSession()
    }
    
    private func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        phaseText = "Tap to Start"
        phaseColor = "gray"
        
        // Stop the HealthKit Workout
        endWorkoutSession()
    }
    
    private func runCycle() {
        guard isActive else { return }
        switch cycleStep {
        case 0: // INHALE
            phaseText = "Breathe In..."
            phaseColor = "green"
            WKInterfaceDevice.current().play(.directionUp)
        case 1: // HOLD
            phaseText = "Hold..."
            phaseColor = "yellow"
            WKInterfaceDevice.current().play(.stop)
        case 2: // EXHALE
            phaseText = "Breathe Out..."
            phaseColor = "blue"
            WKInterfaceDevice.current().play(.directionDown)
        default: break
        }
    }
    
    // MARK: - HealthKit Workout Logic
    
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody // Appropriate for breathing
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                // Handle error if needed
                if !success { print("Error starting collection: \(String(describing: error))") }
            }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            self.builder?.finishWorkout { (workout, error) in
                // Workout saved
            }
        }
    }
    
    // MARK: - Boilerplate Delegates (Required)
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {}
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

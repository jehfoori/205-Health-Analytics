import Foundation
import Combine
import CoreLocation

class SessionManager: ObservableObject {
    @Published var isSessionActive = false
    @Published var currentRuntime: TimeInterval = 0
    @Published var currentHeartRate: Double = 0
    
    // Bio Data cache
    @Published var restingHR: Double = 60.0 // Default fallback
    @Published var userAge: Int = 25 // Default fallback
    
    // Data for the current session (MADE PUBLIC for PostSessionView)
    var hrReadings: [Double] = []
    
    private var startTime: Date?
    private var timer: Timer?
    private var isSimulationMode = true // Set to false when deploying to real device
    
    var activeZone: ChallengeZone?
    
    private let healthManager = HealthKitManager.shared
    
    // Start a session for a specific Zone
    func startSession() {
        // 1. Fetch Bio Data immediately so it's ready for the end
        fetchBioData()
        
        isSessionActive = true
        startTime = Date()
        hrReadings = []
        currentRuntime = 0
        
        // Start the timer to update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopSession(for zone: ChallengeZone) {
        // We ONLY stop the timer here.
        // We do NOT save to disk yet. The PostSessionView will handle that.
        timer?.invalidate()
        
        // Note: We keep isSessionActive = true until the PostView dismisses
        // so the data doesn't get wiped before the user rates it.
    }

    private func tick() {
        guard let start = startTime else { return }
        currentRuntime = Date().timeIntervalSince(start)
        
        if isSimulationMode {
            // SIMULATOR MODE: Generate fake anxiety curve
            // Fluctuate between 100 and 130 BPM
            let fakeHR = Double.random(in: 100...130)
            DispatchQueue.main.async {
                self.currentHeartRate = fakeHR
                self.hrReadings.append(fakeHR)
            }
        } else {
            // REAL DEVICE MODE: Fetch from HealthKit
            healthManager.fetchMostRecentHeartRate { [weak self] bpm, _, _ in
                guard let self = self, let bpm = bpm else { return }
                
                DispatchQueue.main.async {
                    self.currentHeartRate = bpm
                    self.hrReadings.append(bpm)
                }
            }
        }
    }
    
    // Call this when app launches or session starts
    func fetchBioData() {
        healthManager.fetchRestingHeartRate { [weak self] bpm, _ in
            if let bpm = bpm { self?.restingHR = bpm }
        }
        healthManager.fetchUserAge { [weak self] age, _ in
            if let age = age { self?.userAge = age }
        }
    }
    
    // The "Medical" Calculation
    func calculatePhysiologicalScore(peakBPM: Double) -> Double {
        // Karvonen Formula: %Intensity = (Target - Resting) / (Max - Resting)
        let maxHR = Double(220 - userAge)
        let hrReserve = maxHR - restingHR
        
        if hrReserve <= 0 { return 0 } // Avoid division by zero safety
        
        let rise = peakBPM - restingHR
        let intensity = (rise / hrReserve) * 100
        
        // Clamp result between 0 and 100
        return min(max(intensity, 0), 100)
    }
}

import Foundation
import Combine
import CoreLocation

class SessionManager: ObservableObject {
    @Published var isSessionActive = false
    @Published var currentRuntime: TimeInterval = 0
    @Published var currentHeartRate: Double = 0
    
    // Data for the current session
    private var hrReadings: [Double] = []
    private var startTime: Date?
    private var timer: Timer?
    private var isSimulationMode = true // Set to false when deploying to real device
    
    var activeZone: ChallengeZone?
    
    private let healthManager = HealthKitManager.shared
    
    // Start a session for a specific Zone
    func startSession() {
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
        isSessionActive = false
        timer?.invalidate()
        
        guard let start = startTime else { return }
        let totalTime = Date().timeIntervalSince(start)
        
        // Calculate stats
        let peak = hrReadings.max() ?? 0
        let low = hrReadings.min() ?? 0
        let avg = hrReadings.isEmpty ? 0 : hrReadings.reduce(0, +) / Double(hrReadings.count)
        
        let newSession = ExposureSession(
            id: UUID(),
            zoneID: zone.id,
            date: Date(),
            duration: totalTime,
            peakHR: peak,
            lowestHR: low,
            avgHR: avg,
            stepCount: 0, // We will hook this up later
            hrReadings: hrReadings
        )
        
        print("SESSION SAVED: \(newSession)")
        
        // NEW: Persist to disk
        DispatchQueue.main.async {
            SessionDataStore.shared.addSession(newSession)
        }
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
}

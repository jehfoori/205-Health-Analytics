import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isSessionActive = false
    @Published var currentRuntime: TimeInterval = 0
    @Published var currentHeartRate: Double = 0
    
    // Bio Data cache
    @Published var restingHR: Double = 60.0
    @Published var userAge: Int = 25
    
    // Data for the current session
    var hrReadings: [Double] = []
    
    private var startTime: Date?
    private var timer: Timer?
    
    // Track the timestamp of the last sample we successfully read
    private var lastSampleDate: Date?
    
    // MARK: - DEMO MODE SWITCH
    // Set this to TRUE for your presentation.
    // It generates realistic, "Cinematic" data so you can show off the features safely.
    // Set to FALSE to attempt reading from the real Watch.
    @Published var isSimulationMode = true
    
    var activeZone: ChallengeZone?
    private let healthManager = HealthKitManager.shared
    
    // MARK: - Setup
    func requestPermissions() {
        // Even in simulation mode, we ask for permissions so the flow looks real
        print("Requesting HealthKit permissions...")
        healthManager.requestAuthorization { [weak self] success, error in
            if success {
                print("HK Permissions Granted.")
                self?.fetchBioData()
            }
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        print("Starting session flow (Simulation: \(isSimulationMode))...")
        self.startTimerLoop()
        
        // If we are using real data, start the observer
        if !isSimulationMode {
            healthManager.startObservingHeartRate { [weak self] in
                Task { @MainActor in
                    self?.fetchRealHeartRate()
                }
            }
        }
    }
    
    func stopSession(for zone: ChallengeZone) {
        timer?.invalidate()
        timer = nil
        if !isSimulationMode {
            healthManager.stopObservingHeartRate()
        }
    }

    private func startTimerLoop() {
        Task { @MainActor in
            self.isSessionActive = true
            self.startTime = Date()
            self.hrReadings = []
            self.currentRuntime = 0
            self.lastSampleDate = nil
            
            self.timer?.invalidate()
            
            let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tick()
            }
            RunLoop.current.add(newTimer, forMode: .common)
            self.timer = newTimer
        }
    }
    
    private func tick() {
        guard let start = startTime else { return }
        currentRuntime = Date().timeIntervalSince(start)
        
        if isSimulationMode {
            generateCinematicData()
        } else {
            fetchRealHeartRate()
        }
    }
    
    private func fetchRealHeartRate() {
        healthManager.fetchMostRecentHeartRate { [weak self] bpm, sampleDate, error in
            guard let self = self else { return }
            if let error = error { return }
            
            Task { @MainActor in
                guard let bpm = bpm, let sampleDate = sampleDate else { return }
                
                // Duplicate/Stale check
                if let lastDate = self.lastSampleDate, lastDate == sampleDate {
                    return
                }
                
                print("HK FRESH DATA: \(Int(bpm)) BPM")
                self.lastSampleDate = sampleDate
                self.currentHeartRate = bpm
                self.hrReadings.append(bpm)
            }
        }
    }
    
    // MARK: - Demo Data Logic
    private func generateCinematicData() {
        let demoHR: Double
        
        switch currentRuntime {
        case 0..<20:
            demoHR = 80 + (currentRuntime * Double.random(in: 0...5)) // Rises to ~120
        case 20..<50:
            demoHR = 130 + Double.random(in: -5...5) // Spikes around 130
        case 50..<80:
            let progress = (currentRuntime - 50) / 30.0
            demoHR = 130 - (40 * progress) // Drops back down
        default:
            demoHR = 90 + Double.random(in: -3...3) // Steady state
        }
        
        self.currentHeartRate = demoHR
        self.hrReadings.append(demoHR)
    }
    
    func fetchBioData() {
        healthManager.fetchRestingHeartRate { [weak self] bpm, _ in
            if let bpm = bpm { Task { @MainActor in self?.restingHR = bpm } }
        }
        healthManager.fetchUserAge { [weak self] age, _ in
            if let age = age { Task { @MainActor in self?.userAge = age } }
        }
    }
    
    func calculatePhysiologicalScore(peakBPM: Double) -> Double {
        let maxHR = Double(220 - userAge)
        let hrReserve = maxHR - restingHR
        if hrReserve <= 0 { return 0 }
        let rise = peakBPM - restingHR
        return min(max((rise / hrReserve) * 100, 0), 100)
    }
}

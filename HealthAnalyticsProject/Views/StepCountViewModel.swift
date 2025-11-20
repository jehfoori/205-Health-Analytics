import SwiftUI
import HealthKit
import Combine

// MARK: - ViewModel
final class StepCountViewModel: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var statusMessage: String = "Requesting HealthKit access…"
    
    @Published var hrvMilliseconds: Double? = nil
    @Published var latestHeartRateBPM: Double? = nil
    @Published var latestHeartRateTime: Date? = nil
    @Published var latestLocationText: String = "Location: —"
    
    var hrvDisplayText: String {
            if let hrv = hrvMilliseconds {
                // Round as you like
                return String(format: "%.0f ms", hrv)
            } else {
                return "—"
            }
        }
    var heartRateDisplayText: String {
        if let bpm = latestHeartRateBPM {
            return String(format: "%.0f bpm", bpm)
        } else {
            return "—"
        }
    }
    var locationDisplayText: String {
        latestLocationText
    }
    
    private let healthKitManager = HealthKitManager.shared
    private let locationManager = SedentaryLocationManager.shared
    private let hrLocationStore = HeartRateLocationStore.shared
    private var refreshTimer: Timer?
    
    init() {
        
    }
    
    func requestHealthKitAccess() {
        DispatchQueue.main.async {
            self.healthKitManager.requestAuthorization { [weak self] success, error in
                guard let self = self else { return }

                if let error = error {
                    self.statusMessage = "Authorization error: \(error.localizedDescription)"
                    return
                }

                if success {
                    self.statusMessage = "Authorized. Fetching today’s data…"
                    self.refreshAll()

                    // Refresh every 5 minutes while app is active
                    self.startRefreshTimer()
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
                self.refreshHRV()
                self.refreshHeartRateAndLocation()
            } else {
                self.statusMessage = "No step data available."
            }
        }
    }

    func refreshHRV() {
        healthKitManager.fetchTodayHRV { [weak self] hrv, error in
                guard let self = self else { return }
                
                if let error = error {
                    // You can decide whether to overwrite statusMessage or not
                    print("Error fetching HRV: \(error.localizedDescription)")
                    return
                }
                
                self.hrvMilliseconds = hrv
            }
    }
    
    func refreshHeartRateAndLocation() {
        // Snapshot current location
        let currentLocation = locationManager.lastKnownLocation
        if let loc = currentLocation {
            let lat = loc.coordinate.latitude
            let lon = loc.coordinate.longitude
            latestLocationText = String(format: "Location: %.4f, %.4f", lat, lon)
        } else {
            latestLocationText = "Location: —"
        }

        // Fetch most recent HR
        healthKitManager.fetchMostRecentHeartRate { [weak self] bpm, timestamp, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching heart rate:", error.localizedDescription)
            }

            self.latestHeartRateBPM = bpm
            self.latestHeartRateTime = timestamp

            // Store combined sample if we have both HR and location
            if let bpm = bpm,
               let timestamp = timestamp,
               let loc = currentLocation {
                self.hrLocationStore.addSample(bpm: bpm, location: loc, at: timestamp)
            }
        }
    }


    func refreshAll() {
        refreshStepCount()
        refreshHRV()
        refreshHeartRateAndLocation()
    }
    private func startRefreshTimer() {
        // Cancel any existing timer before starting a new one
        refreshTimer?.invalidate()
        
        // Fire every 5 minutes (300 seconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300,
                                            repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If you have a helper that refreshes everything:
            // self.refreshAll()
            
            // Or call the individual refreshes directly:
            self.refreshStepCount()
            self.refreshHRV()
            self.refreshHeartRateAndLocation()
        }
    }


}

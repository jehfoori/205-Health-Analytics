//
//  SedentaryLocationManager.swift
//  HealthAnalyticsProject
//
//  Created by Aaron Zhao on 11/19/25.
//


import Foundation
import CoreLocation
import UserNotifications
import Combine

final class SedentaryLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = SedentaryLocationManager()

    private let locationManager = CLLocationManager()
    private let sedentaryNotificationID = "sedentaryNotificationID"

    // How far the user has to move to be considered "not sedentary" (in meters)
    private let movementThreshold: CLLocationDistance = 25

    private var lastSignificantLocation: CLLocation?
    private var isTracking = false

    @Published var currentLocation: CLLocation?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
    }


    // Call this once from your app to start tracking
    func start() {
        guard !isTracking else { return }
        isTracking = true
        requestPermissionsIfNeeded()
    }

    // MARK: - Permissions

    private func requestPermissionsIfNeeded() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            // Triggers the "Always and When In Use" permission dialog
            locationManager.requestAlwaysAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()

        case .denied, .restricted:
            // In a real app you might show an in-app message guiding user to Settings
            break

        @unknown default:
            break
        }

        // Ask for local notification permission (so we can alert after 1 hour)
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in
            // You could handle errors or log here if you want
        }
    }

    private func startLocationUpdates() {
        // For a real product you might prefer significant location changes,
        // but for a class project this is fine.
        locationManager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startLocationUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last else { return }

        // NEW: expose the latest location to SwiftUI
        currentLocation = current

        if let last = lastSignificantLocation {
            let distance = current.distance(from: last)

            if distance >= movementThreshold {
                // User moved enough → reset sedentary timer
                lastSignificantLocation = current
                cancelSedentaryNotification()
                scheduleSedentaryNotification()
            }
            // If distance < threshold, we stay “sedentary” and let the existing timer run
        } else {
            // First location we’ve seen
            lastSignificantLocation = current
            scheduleSedentaryNotification()
        }
    }


    // MARK: - Notification logic

    private func scheduleSedentaryNotification() {
        let center = UNUserNotificationCenter.current()

        // Make sure we only ever have one "sedentary" pending notification
        center.removePendingNotificationRequests(withIdentifiers: [sedentaryNotificationID])

        let content = UNMutableNotificationContent()
        content.title = "Time to move?"
        content.body = "You haven’t moved much in the last hour."
        content.sound = .default

        // Fire in 1 hour (3600 seconds) unless we cancel it first due to movement
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

        let request = UNNotificationRequest(
            identifier: sedentaryNotificationID,
            content: content,
            trigger: trigger
        )

        center.add(request, withCompletionHandler: nil)
    }

    private func cancelSedentaryNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [sedentaryNotificationID])
    }
}

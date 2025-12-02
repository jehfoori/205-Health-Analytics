//
//  ZoneDataStore.swift
//  HealthAnalyticsProject
//
//  Created by Jeffrey Huang on 11/22/25.
//
import SwiftUI
import Foundation
import Combine

@MainActor
class ZoneDataStore: ObservableObject {
    static let shared = ZoneDataStore()
    
    @Published var zones: [ChallengeZone] = []
    
    private let fileName = "challenge_zones.json"
    
    init() {
        loadZones()
    }
    
    // MARK: - CRUD Operations
    
    func addZone(name: String, latitude: Double, longitude: Double) {
        let newZone = ChallengeZone(
            id: UUID(),
            name: name,
            latitude: latitude,
            longitude: longitude,
            radius: 50.0 // Default 50m radius
        )
        zones.append(newZone)
        saveZones()
    }
    
    func deleteZone(at offsets: IndexSet) {
            let sessionStore = SessionDataStore.shared
            
            // For each index, delete sessions tied to that zone, then remove the zone
            for index in offsets {
                let zone = zones[index]
                sessionStore.deleteSessions(for: zone.id)
            }
            
            zones.remove(atOffsets: offsets)
            saveZones()
        }
        
        /// Convenience: delete a specific zone instance (used by ZoneMapView button)
        func deleteZone(_ zone: ChallengeZone) {
            let sessionStore = SessionDataStore.shared
            
            sessionStore.deleteSessions(for: zone.id)
            zones.removeAll { $0.id == zone.id }
            saveZones()
        }
    
    // MARK: - Persistence Logic
    
    private func saveZones() {
        do {
            let data = try JSONEncoder().encode(zones)
            try data.write(to: fileURL())
        } catch {
            print("Error saving zones: \(error)")
        }
    }
    
    private func loadZones() {
        do {
            let data = try Data(contentsOf: fileURL())
            zones = try JSONDecoder().decode([ChallengeZone].self, from: data)
        } catch {
            // It's okay if the file doesn't exist yet (first launch)
            print("No saved zones found or error loading: \(error)")
        }
    }
    
    private func fileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
}

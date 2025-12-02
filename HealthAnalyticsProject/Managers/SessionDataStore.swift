import Foundation
import Combine

@MainActor
class SessionDataStore: ObservableObject {
    static let shared = SessionDataStore()
    
    @Published var sessions: [ExposureSession] = []
    
    private let fileName = "exposure_history.json"
    
    init() {
        loadSessions()
    }
    
    func addSession(_ session: ExposureSession) {
        sessions.append(session)
        saveSessions()
    }
    func deleteSession(_ session: ExposureSession) {
        // Remove any session with the same id
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    
    // Helper: Get all sessions for a specific zone (e.g., "Grocery Store")
    func sessions(for zoneID: UUID) -> [ExposureSession] {
        return sessions.filter { $0.zoneID == zoneID }.sorted(by: { $0.date > $1.date })
    }
    func deleteSessions(for zoneID: UUID) {
        sessions.removeAll { $0.zoneID == zoneID }
        saveSessions()
    }

    
    // MARK: - Persistence
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL())
        } catch {
            print("Error saving history: \(error)")
        }
    }
    
    private func loadSessions() {
        do {
            let data = try Data(contentsOf: fileURL())
            sessions = try JSONDecoder().decode([ExposureSession].self, from: data)
        } catch {
            print("No history found (first launch).")
        }
    }
    
    private func fileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
}

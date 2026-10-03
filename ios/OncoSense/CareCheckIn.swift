import Foundation

struct CareCheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    let fatigue: Int
    let appetite: Int
    let pain: Int
    let fever: Bool
    let note: String
}

@MainActor
final class CareCheckInStore: ObservableObject {
    @Published private(set) var entries: [CareCheckIn] = []
    private let key = "oncosense.care.checkins.v1"

    init() { load() }

    func save(fatigue: Int, appetite: Int, pain: Int, fever: Bool, note: String) {
        let entry = CareCheckIn(id: UUID(), date: .now, fatigue: fatigue, appetite: appetite, pain: pain, fever: fever, note: note)
        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(90))
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let values = try? JSONDecoder().decode([CareCheckIn].self, from: data) else { return }
        entries = values.sorted { $0.date > $1.date }
    }
}

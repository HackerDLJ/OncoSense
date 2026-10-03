import SwiftUI

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

struct CareView: View {
    @StateObject private var store = CareCheckInStore()
    @State private var fatigue = 0
    @State private var appetite = 0
    @State private var pain = 0
    @State private var fever = false
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("A short daily check-in adds human context to your wearable data. These notes stay on this device and are not used to diagnose cancer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("How are you feeling?") {
                    RatingRow(title: "Fatigue", value: $fatigue)
                    RatingRow(title: "Appetite", value: $appetite)
                    RatingRow(title: "Pain", value: $pain)
                    Toggle("Fever / unusually hot", isOn: $fever)
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Button("Save today's check-in") {
                    store.save(fatigue: fatigue, appetite: appetite, pain: pain, fever: fever, note: note)
                    note = ""
                    saved = true
                }
                .buttonStyle(.borderedProminent)

                if saved {
                    Label("Saved on this iPhone", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Section("Recent check-ins") {
                    if store.entries.isEmpty {
                        Text("No check-ins yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.entries.prefix(14)) { entry in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(entry.date, style: .date)
                                    Spacer()
                                    if entry.fever { Label("Fever", systemImage: "thermometer.medium") }
                                }
                                Text("Fatigue \(entry.fatigue)/3 · Appetite \(entry.appetite)/3 · Pain \(entry.pain)/3")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !entry.note.isEmpty {
                                    Text(entry.note)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Care check-in")
        }
    }
}

private struct RatingRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
            Picker(title, selection: $value) {
                Text("None").tag(0)
                Text("Mild").tag(1)
                Text("Moderate").tag(2)
                Text("Severe").tag(3)
            }
            .pickerStyle(.segmented)
        }
    }
}

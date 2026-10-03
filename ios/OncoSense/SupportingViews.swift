import SwiftUI

struct CareView: View {
    @StateObject private var checkIns = CareCheckInStore()
    @State private var fatigue = 3
    @State private var appetite = 3
    @State private var pain = 0
    @State private var fever = false
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Wearable signals cannot capture everything. Record how you feel so OncoSense can keep physiological data and personal context side by side.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Today") {
                    Stepper("Fatigue: \(fatigue)/5", value: $fatigue, in: 0...5)
                    Stepper("Appetite: \(appetite)/5", value: $appetite, in: 0...5)
                    Stepper("Pain: \(pain)/10", value: $pain, in: 0...10)
                    Toggle("Fever or unusually hot", isOn: $fever)
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                    Button("Save check-in") {
                        checkIns.save(fatigue: fatigue, appetite: appetite, pain: pain, fever: fever, note: note)
                        note = ""
                    }
                }

                Section("Recent check-ins") {
                    if checkIns.entries.isEmpty {
                        Text("No check-ins yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(checkIns.entries.prefix(7)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date, style: .date)
                                    .font(.headline)
                                Text("Fatigue \(entry.fatigue)/5 · Appetite \(entry.appetite)/5 · Pain \(entry.pain)/10")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if entry.fever { Text("Fever/hot feeling reported") }
                                if !entry.note.isEmpty { Text(entry.note).font(.caption) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Care")
        }
    }
}

struct LearnView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("What OncoSense does") {
                    Text("OncoSense builds a personal physiological baseline from health data you authorize and looks for persistent changes from that baseline.")
                    Text("It is a screening and monitoring research tool, not a cancer diagnosis. A pattern change needs clinical interpretation and, when appropriate, established medical testing.")
                }
                Section("Why the baseline matters") {
                    Text("A single heart-rate or sleep measurement is noisy. Trends over time provide more useful context about what is normal for one person.")
                }
                Section("The signals") {
                    Text("OncoSense can use resting heart rate, heart rate, HRV, respiratory rate, wrist temperature, sleep, activity, steps, active energy and weight when those data are available in Apple Health.")
                }
                Section("Data quality") {
                    Text("Missing measurements are shown as missing. OncoSense never fills gaps with invented health values.")
                }
            }
            .navigationTitle("Learn")
        }
    }
}

struct WatchConnectionView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(store.watchStatusText, systemImage: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch")
                        .font(.headline)
                }
                Section("Connection") {
                    LabeledContent("Session", value: store.sync.isActivated ? "Activated" : "Not active")
                    LabeledContent("Reachability", value: store.sync.isReachable ? "Reachable now" : "Not reachable")
                    LabeledContent("Queued", value: "\(store.sync.pendingTransfers)")
                    LabeledContent("Last sync", value: store.sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Never")
                    LabeledContent("Last received", value: store.sync.lastReceived.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Never")
                }
                Section {
                    Button("Sync latest health snapshot") {
                        store.syncLatestToWatch()
                    }
                    Button("Refresh from Apple Health") {
                        Task { await store.refresh() }
                    }
                }
                Section("What sync means") {
                    Text("The iPhone and Watch exchange the latest real HealthKit snapshot. Immediate context is used when reachable; queued transfer keeps a snapshot available for later delivery when the devices cannot communicate at that moment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Apple Watch")
        }
    }
}

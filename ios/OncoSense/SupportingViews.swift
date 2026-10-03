import SwiftUI
import UIKit

struct CareView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @StateObject private var checkIns = CareCheckInStore()
    @State private var fatigue = 3
    @State private var appetite = 3
    @State private var pain = 0
    @State private var fever = false
    @State private var note = ""
    @State private var saved = false
    @FocusState private var noteFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    contextHeader
                    CancerCareSection()
                    todayCard
                    noteCard
                    recentCard
                    privacyCard
                }
                .padding()
                .padding(.bottom, 24)
            }
            .navigationTitle("Care")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { finishNoteEntry() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if noteFieldFocused {
                    EmptyView()
                } else if saved {
                    Label("Check-in saved", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var contextHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("YOUR CONTEXT", systemImage: "person.text.rectangle.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("How are you feeling today?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Your notes sit beside your real HealthKit trends, so you can remember what was happening around a change.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TODAY").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Text(Date.now, style: .date).font(.caption).foregroundStyle(.secondary)
            }

            CareScale(title: "Fatigue", subtitle: fatigueLabel, value: $fatigue, range: 0...5, icon: "battery.75percent")
            Divider()
            CareScale(title: "Appetite", subtitle: appetiteLabel, value: $appetite, range: 0...5, icon: "fork.knife")
            Divider()
            CareScale(title: "Pain", subtitle: pain == 0 ? "None" : "\(pain)/10", value: $pain, range: 0...10, icon: "bandage.fill")
            Divider()
            Toggle(isOn: $fever) {
                Label("Fever or unusually hot", systemImage: "thermometer.medium")
            }
            .tint(.orange)
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADD CONTEXT").font(.caption.bold()).foregroundStyle(.secondary)
            TextField("Anything you want to remember?", text: $note, axis: .vertical)
                .lineLimit(3...7)
                .focused($noteFieldFocused)
                .submitLabel(.done)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onSubmit { finishNoteEntry() }

            Button(action: saveCheckIn) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save today's check-in")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && fatigue == 3 && appetite == 3 && pain == 0 && !fever)
            .opacity((note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && fatigue == 3 && appetite == 3 && pain == 0 && !fever) ? 0.55 : 1)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT CHECK-INS").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if !checkIns.entries.isEmpty { Text("\(checkIns.entries.count) saved").font(.caption).foregroundStyle(.secondary) }
            }

            if checkIns.entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "note.text.badge.plus").font(.title2).foregroundStyle(.tint)
                    Text("Your care timeline starts here").font(.headline)
                    Text("A quick check-in gives your future trends useful context without trying to explain them for you.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(checkIns.entries.prefix(5)) { entry in
                    CareHistoryRow(entry: entry)
                    if entry.id != checkIns.entries.prefix(5).last?.id { Divider() }
                }
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var privacyCard: some View {
        Label("Care notes are stored locally on this device. They are context you add yourself and are not a diagnosis.", systemImage: "lock.shield")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var fatigueLabel: String {
        switch fatigue { case 0: return "None"; case 1: return "Very low"; case 2: return "Low"; case 3: return "Moderate"; case 4: return "High"; default: return "Very high" }
    }

    private var appetiteLabel: String {
        switch appetite { case 0: return "Very poor"; case 1: return "Poor"; case 2: return "Reduced"; case 3: return "Usual"; case 4: return "Good"; default: return "Very good" }
    }

    private func finishNoteEntry() {
        noteFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func saveCheckIn() {
        finishNoteEntry()
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        checkIns.save(fatigue: fatigue, appetite: appetite, pain: pain, fever: fever, note: trimmed)
        note = ""
        fatigue = 3
        appetite = 3
        pain = 0
        fever = false
        withAnimation(.easeInOut(duration: 0.2)) { saved = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { withAnimation(.easeInOut(duration: 0.2)) { saved = false } }
        }
    }
}

private struct CareScale: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon).font(.subheadline.weight(.semibold))
                Spacer()
                Text(subtitle).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 7) {
                ForEach(range, id: \.self) { item in
                    Button { value = item } label: {
                        Text("\(item)")
                            .font(.caption.bold().monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(item == value ? Color.accentColor : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(item == value ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CareHistoryRow: View {
    let entry: CareCheckIn
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(entry.date, style: .date).font(.subheadline.weight(.semibold))
                Spacer()
                Text(entry.date, style: .time).font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                MiniPill(title: "Fatigue", value: "\(entry.fatigue)/5")
                MiniPill(title: "Appetite", value: "\(entry.appetite)/5")
                MiniPill(title: "Pain", value: "\(entry.pain)/10")
            }
            if entry.fever { Label("Fever/hot feeling reported", systemImage: "thermometer.medium").font(.caption).foregroundStyle(.orange) }
            if !entry.note.isEmpty { Text(entry.note).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
        .padding(.vertical, 4)
    }
}

private struct MiniPill: View {
    let title: String; let value: String
    var body: some View {
        Text("\(title) \(value)").font(.caption2.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 5).background(.secondary.opacity(0.10), in: Capsule())
    }
}

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("What OncoSense does") {
                    Text("OncoSense tracks real health measurements, helps you visualize longitudinal trends, and compares recent observations with your personal baseline.")
                    Text("It helps you document changes and prepare useful context for follow-up conversations. It does not diagnose cancer, predict cancer risk, recommend treatment, or replace established screening and clinical care.")
                }
                Section("The scope") {
                    Text("OncoSense is focused on tracking, visualization, longitudinal documentation, and communication support. A persistent change can have many explanations and needs appropriate clinical interpretation.")
                }
                Section("Why the baseline matters") {
                    Text("A single measurement can be noisy. Trends over time provide more useful context about what is normal for one person.")
                }
                Section("The signals") {
                    Text("OncoSense can use resting heart rate, heart rate, HRV, respiratory rate, sleeping wrist temperature, sleep, activity, steps, active energy and weight when those data are available in Apple Health.")
                }
                Section("Data quality") {
                    Text("Missing measurements are shown as missing. OncoSense never fills gaps with invented health values.")
                }
            }
            .navigationTitle("Learn")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct WatchConnectionView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section { Label(store.watchStatusText, systemImage: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch").font(.headline) }
                Section("Connection") {
                    LabeledContent("Session", value: store.sync.isActivated ? "Activated" : "Not active")
                    LabeledContent("Reachability", value: store.sync.isReachable ? "Reachable now" : "Not reachable")
                    LabeledContent("Queued", value: "\(store.sync.pendingTransfers)")
                    LabeledContent("Last sync", value: store.sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Never")
                    LabeledContent("Last received", value: store.sync.lastReceived.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Never")
                }
                Section {
                    Button("Sync latest health snapshot") { store.syncLatestToWatch() }
                    Button("Refresh from Apple Health") { Task { await store.refresh() } }
                }
                Section("What sync means") {
                    Text("The iPhone and Watch exchange the latest real HealthKit snapshot. Immediate context is used when reachable; queued transfer keeps a snapshot available for later delivery when the devices cannot communicate at that moment.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Apple Watch")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

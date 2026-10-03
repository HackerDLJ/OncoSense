import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject private var health: HealthDataManager
    @EnvironmentObject private var sync: OncoSenseConnectivity
    @State private var snapshot: HealthSnapshot?
    @State private var result: ScreeningResult?
    @State private var history: [HealthSnapshot] = []
    @State private var healthReady = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var showSetup = !UserDefaults.standard.bool(forKey: "oncosense.watch.setup.v1")

    private let historyKey = "oncosense.watch.snapshots.v2"

    var body: some View {
        Group {
            if showSetup {
                setupView
            } else {
                dashboard
            }
        }
        .task {
            loadHistory()
            sync.activate()
            sync.onSnapshot = { incoming in
                Task { @MainActor in
                    snapshot = incoming
                    append(incoming)
                }
            }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.system(size: 38))
                    .foregroundStyle(.tint)
                Text("OncoSense")
                    .font(.title2.bold())
                Text("Your Watch is the collection point. Your iPhone is the long-term health view.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Label("Real HealthKit data only", systemImage: "checkmark.shield.fill")
                    .font(.caption2)
                Label("Queued Watch → iPhone sync", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                Label("No fake measurements", systemImage: "slash.circle")
                    .font(.caption2)

                Button("Connect Apple Health") { connectHealth() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRefreshing)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.orange)
                }

                Text("OncoSense highlights changes in your personal health pattern. It does not diagnose cancer.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }

    private var dashboard: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    header
                    pattern
                    signalSection
                    syncSection
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("OncoSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { refresh() } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(isRefreshing)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            HStack {
                Label(sync.isReachable ? "iPhone connected" : "iPhone not reachable", systemImage: sync.isReachable ? "iphone.and.arrow.forward" : "iphone")
                    .font(.caption2.weight(.semibold))
                Spacer()
                Text("\(availableCount)/10")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("Real signals from Apple Health")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var pattern: some View {
        VStack(spacing: 5) {
            if let result {
                Text(result.state == .low ? "Close to baseline" : result.state == .watch ? "Change detected" : "Multiple changes")
                    .font(.title3.bold())
                Text(result.summary)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("Pattern score \(result.signal)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text("Building baseline")
                    .font(.title3.bold())
                Text("Collect more real measurements before interpreting a pattern.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var signalSection: some View {
        VStack(spacing: 8) {
            SignalRow(title: "Resting HR", value: snapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill")
            SignalRow(title: "Heart rate", value: snapshot?.heartRate.map { "\(Int($0)) bpm" }, icon: "waveform.path.ecg")
            SignalRow(title: "HRV", value: snapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle")
            SignalRow(title: "Respiratory", value: snapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill")
            SignalRow(title: "Wrist temp", value: snapshot?.temperature.map { String(format: "%.2f°C", $0) }, icon: "thermometer.medium")
            SignalRow(title: "Sleep", value: snapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill")
            SignalRow(title: "Steps", value: snapshot?.steps.map { "\(Int($0))" }, icon: "figure.walk")
            SignalRow(title: "Energy", value: snapshot?.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill")
            SignalRow(title: "Exercise", value: snapshot?.activityMinutes.map { "\(Int($0)) min" }, icon: "figure.run")
            SignalRow(title: "Weight", value: snapshot?.weightKg.map { String(format: "%.1f kg", $0) }, icon: "scalemass.fill")
        }
    }

    private var syncSection: some View {
        VStack(spacing: 7) {
            Button(isRefreshing ? "Reading Health…" : "Refresh & Sync") { refresh() }
                .buttonStyle(.borderedProminent)
                .disabled(isRefreshing)
            if let lastSync = sync.lastSync {
                Text("Last transfer \(lastSync, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if sync.pendingTransfers > 0 {
                Text("\(sync.pendingTransfers) transfer(s) queued for iPhone")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var availableCount: Int {
        guard let snapshot else { return 0 }
        return [snapshot.restingHeartRate, snapshot.heartRate, snapshot.hrv, snapshot.respiratoryRate,
                snapshot.temperature, snapshot.sleepHours, snapshot.activityMinutes, snapshot.steps,
                snapshot.activeEnergy, snapshot.weightKg].compactMap { $0 }.count
    }

    private func connectHealth() {
        isRefreshing = true
        Task {
            do {
                try await health.requestAuthorization()
                healthReady = true
                UserDefaults.standard.set(true, forKey: "oncosense.watch.setup.v1")
                showSetup = false
                refresh()
            } catch {
                errorMessage = error.localizedDescription
                isRefreshing = false
            }
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        Task {
            defer { isRefreshing = false }
            do {
                if !healthReady { try await health.requestAuthorization(); healthReady = true }
                let fresh = try await health.fetchLatestSnapshot()
                snapshot = fresh
                append(fresh)
                sync.send(snapshot: fresh)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func append(_ fresh: HealthSnapshot) {
        guard !history.contains(where: { $0.id == fresh.id }) else { return }
        history.append(fresh)
        history.sort { $0.timestamp > $1.timestamp }
        history = Array(history.prefix(120))
        result = ScreeningEngine.analyze(history)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let values = try? JSONDecoder().decode([HealthSnapshot].self, from: data) else { return }
        history = values.sorted { $0.timestamp > $1.timestamp }
        snapshot = history.first
        result = ScreeningEngine.analyze(history)
        healthReady = !history.isEmpty
    }
}

private struct SignalRow: View {
    let title: String
    let value: String?
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .frame(width: 20)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "No data")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
        .padding(.vertical, 3)
    }
}

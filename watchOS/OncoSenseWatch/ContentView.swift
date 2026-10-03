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
    @State private var showSetup = !UserDefaults.standard.bool(forKey: "oncosense.watch.setup.v2")
    @State private var showAllSignals = false

    private let historyKey = "oncosense.watch.snapshots.v3"

    var body: some View {
        Group {
            if showSetup { setupView } else { dashboard }
        }
        .task {
            loadHistory()
            sync.onSnapshot = { incoming in
                Task { @MainActor in
                    snapshot = incoming
                    append(incoming)
                }
            }
            sync.onSnapshotRequest = {
                Task { @MainActor in
                    await refreshAndSend()
                }
            }
            sync.activate()
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "applewatch.and.arrow.forward")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
                Text("OncoSense")
                    .font(.title3.bold())
                Text("Your Watch reads the health data available to it and sends the latest snapshot to your iPhone.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Label("Real HealthKit data", systemImage: "checkmark.shield.fill")
                    Label("Automatic iPhone sync", systemImage: "iphone.and.arrow.forward")
                    Label("No invented measurements", systemImage: "slash.circle")
                }
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

                Text("OncoSense monitors changes in your personal pattern. It does not diagnose cancer.")
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
                VStack(spacing: 9) {
                    connectionCard
                    patternCard
                    keySignals
                    Button("View all signals") { showAllSignals = true }
                        .font(.caption)
                    syncButton
                }
                .padding(.horizontal, 7)
            }
            .navigationTitle("OncoSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { refresh() } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(isRefreshing)
                }
            }
            .sheet(isPresented: $showAllSignals) {
                AllSignalsView(snapshot: snapshot)
            }
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 7) {
            Image(systemName: sync.isReachable ? "iphone.and.arrow.forward" : "iphone")
                .foregroundStyle(sync.isReachable ? .green : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(sync.isReachable ? "iPhone connected" : "Waiting for iPhone")
                    .font(.caption.bold())
                Text(sync.isActivated ? "WatchConnectivity active" : "Connecting…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(availableCount)/10")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var patternCard: some View {
        VStack(spacing: 4) {
            if let result {
                Text(result.state == .low ? "Close to baseline" : result.state == .watch ? "Change worth watching" : "Repeated changes")
                    .font(.title3.bold())
                Text(result.summary)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("Data quality \(result.dataQuality)%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text("Building your baseline")
                    .font(.title3.bold())
                Text("More real observations are needed before interpreting a pattern.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }

    private var keySignals: some View {
        VStack(spacing: 6) {
            SignalRow(title: "Resting HR", value: snapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill")
            SignalRow(title: "HRV", value: snapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle")
            SignalRow(title: "Respiratory", value: snapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill")
            SignalRow(title: "Sleep", value: snapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill")
            SignalRow(title: "Wrist temp", value: snapshot?.temperature.map { String(format: "%.2f°C", $0) }, icon: "thermometer.medium")
        }
    }

    private var syncButton: some View {
        VStack(spacing: 4) {
            Button(isRefreshing ? "Reading Health…" : "Refresh & Sync") { refresh() }
                .buttonStyle(.borderedProminent)
                .disabled(isRefreshing)
            if let lastSync = sync.lastSync {
                Text("Last sent \(lastSync, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if sync.pendingTransfers > 0 {
                Text("\(sync.pendingTransfers) item(s) queued")
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
    }

    private var availableCount: Int {
        guard let snapshot else { return 0 }
        return [snapshot.restingHeartRate, snapshot.heartRate, snapshot.hrv, snapshot.respiratoryRate,
                snapshot.temperature, snapshot.sleepHours, snapshot.activityMinutes, snapshot.steps,
                snapshot.activeEnergy, snapshot.weightKg].compactMap { $0 }.count
    }

    private func connectHealth() {
        isRefreshing = true
        errorMessage = nil
        Task {
            do {
                try await health.requestAuthorization()
                healthReady = true
                UserDefaults.standard.set(true, forKey: "oncosense.watch.setup.v2")
                showSetup = false
                isRefreshing = false
                await refreshAndSend()
            } catch {
                errorMessage = error.localizedDescription
                isRefreshing = false
            }
        }
    }

    private func refresh() {
        Task { await refreshAndSend() }
    }

    private func refreshAndSend() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        do {
            if !healthReady {
                try await health.requestAuthorization()
                healthReady = true
            }
            let fresh = try await health.fetchLatestSnapshot()
            snapshot = fresh
            append(fresh)
            sync.send(snapshot: fresh)
        } catch {
            errorMessage = error.localizedDescription
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

private struct AllSignalsView: View {
    let snapshot: HealthSnapshot?

    var body: some View {
        NavigationStack {
            List {
                SignalRow(title: "Resting HR", value: snapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill")
                SignalRow(title: "Heart rate", value: snapshot?.heartRate.map { "\(Int($0)) bpm" }, icon: "waveform.path.ecg")
                SignalRow(title: "HRV", value: snapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle")
                SignalRow(title: "Respiratory", value: snapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill")
                SignalRow(title: "Wrist temp", value: snapshot?.temperature.map { String(format: "%.2f°C", $0) }, icon: "thermometer.medium")
                SignalRow(title: "Sleep", value: snapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill")
                SignalRow(title: "Exercise", value: snapshot?.activityMinutes.map { "\(Int($0)) min" }, icon: "figure.run")
                SignalRow(title: "Steps", value: snapshot?.steps.map { "\(Int($0))" }, icon: "figure.walk")
                SignalRow(title: "Energy", value: snapshot?.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill")
                SignalRow(title: "Weight", value: snapshot?.weightKg.map { String(format: "%.1f kg", $0) }, icon: "scalemass.fill")
            }
            .navigationTitle("All signals")
        }
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

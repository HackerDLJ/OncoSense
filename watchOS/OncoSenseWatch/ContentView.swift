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
    @State private var showSetup = !UserDefaults.standard.bool(forKey: "oncosense.watch.setup.v3")
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
            VStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("OncoSense")
                    .font(.title3.bold())
                Text("Use your Watch to collect the real Apple Health measurements available on your device and keep your iPhone view up to date.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(isRefreshing ? "Connecting…" : "Connect Apple Health") {
                    connectHealth()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRefreshing)

                Text("OncoSense tracks changes from your personal baseline. It does not diagnose cancer or recommend treatment.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
        }
    }

    private var dashboard: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    status
                    summary
                    keySignals
                    Button("View all signals") { showAllSignals = true }
                        .font(.caption)
                    Button(isRefreshing ? "Reading Health…" : "Refresh & Sync") {
                        Task { await refreshAndSend() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRefreshing)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .navigationTitle("OncoSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshAndSend() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
            .sheet(isPresented: $showAllSignals) {
                AllSignalsView(snapshot: snapshot)
            }
        }
    }

    private var status: some View {
        HStack(spacing: 7) {
            Image(systemName: sync.counterpartInstalled ? "iphone" : "iphone.slash")
                .foregroundStyle(sync.counterpartInstalled ? .green : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(sync.counterpartInstalled ? "iPhone ready" : "Install OncoSense on iPhone")
                    .font(.caption.bold())
                Text(sync.counterpartInstalled ? "Health data syncs in the background" : "The Watch app cannot sync without its iPhone app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(sync.isActivated ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
        }
        .padding(9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var summary: some View {
        VStack(spacing: 4) {
            if let result {
                Text(result.state == .low ? "Close to your baseline" : result.state == .watch ? "Change worth watching" : "Repeated changes")
                    .font(.headline)
                Text(result.summary)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("Data quality \(result.dataQuality)%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text("Building your baseline")
                    .font(.headline)
                Text("More real observations are needed before describing a pattern.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var keySignals: some View {
        VStack(spacing: 4) {
            SignalRow(title: "Resting HR", value: snapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill")
            SignalRow(title: "HRV", value: snapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle")
            SignalRow(title: "Respiratory", value: snapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill")
            SignalRow(title: "Sleep", value: snapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill")
        }
        .padding(7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var availableCount: Int {
        guard let snapshot else { return 0 }
        return [snapshot.restingHeartRate, snapshot.heartRate, snapshot.hrv, snapshot.respiratoryRate,
                snapshot.temperature, snapshot.sleepHours, snapshot.activityMinutes, snapshot.steps,
                snapshot.activeEnergy, snapshot.weightKg].compactMap { $0 }.count
    }

    private func connectHealth() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        Task {
            do {
                try await health.requestAuthorization()
                healthReady = true
                UserDefaults.standard.set(true, forKey: "oncosense.watch.setup.v3")
                showSetup = false

                // Release the setup lock before entering the shared refresh
                // path. Previously connectHealth() set isRefreshing = true and
                // then called refreshAndSend(), whose guard immediately returned,
                // so the first successful authorization never synced data.
                isRefreshing = false
                await refreshAndSend()
            } catch {
                errorMessage = error.localizedDescription
                isRefreshing = false
            }
        }
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
            .navigationTitle("Signals")
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

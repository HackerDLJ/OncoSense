import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: HealthDataManager
    @EnvironmentObject private var sync: OncoSenseConnectivity
    @State private var snapshot: HealthSnapshot?
    @State private var result: ScreeningResult?
    @State private var healthReady = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("ONCOSENSE")
                    .font(.headline.bold())

                HStack(spacing: 6) {
                    Image(systemName: sync.isReachable ? "iphone.and.arrow.forward" : "iphone")
                    Text(sync.isReachable ? "iPhone connected" : "iPhone not reachable")
                }
                .font(.caption2)
                .foregroundStyle(sync.isReachable ? .green : .secondary)

                if let result {
                    Text(result.state.title)
                        .font(.system(size: 30, weight: .black))
                    Text(result.summary)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "heart.text.square")
                        .font(.largeTitle)
                    Text("No real measurements yet")
                        .font(.headline)
                    Text("Connect Apple Health, then refresh to collect a real snapshot.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                if let snapshot {
                    Divider()
                    MetricRow(title: "Resting HR", value: snapshot.restingHeartRate.map { "\(Int($0)) bpm" } ?? "—")
                    MetricRow(title: "HRV", value: snapshot.hrv.map { "\(Int($0)) ms" } ?? "—")
                    MetricRow(title: "Respiratory", value: snapshot.respiratoryRate.map { String(format: "%.1f/min", $0) } ?? "—")
                    MetricRow(title: "Wrist temp", value: snapshot.temperature.map { String(format: "%.2f°C", $0) } ?? "—")
                    MetricRow(title: "Sleep", value: snapshot.sleepHours.map { String(format: "%.1fh", $0) } ?? "—")
                    MetricRow(title: "Exercise", value: snapshot.activityMinutes.map { "\(Int($0)) min" } ?? "—")
                }

                if !healthReady {
                    Button("Connect Apple Health") {
                        connectHealth()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(isRefreshing ? "Reading Health…" : "Refresh & Sync") {
                        refresh()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRefreshing)
                }

                if let lastSync = sync.lastSync {
                    Text("Last sync \(lastSync, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.orange)
                }

                Text("Health pattern monitoring only · not a cancer diagnosis")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .task {
            sync.activate()
            sync.onSnapshot = { incoming in
                Task { @MainActor in
                    snapshot = incoming
                }
            }
        }
    }

    private func connectHealth() {
        Task {
            do {
                try await health.requestAuthorization()
                healthReady = true
                refresh()
            } catch {
                errorMessage = error.localizedDescription
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
                let fresh = try await health.fetchLatestSnapshot()
                snapshot = fresh
                result = ScreeningEngine.analyze([fresh, fresh])
                sync.send(snapshot: fresh)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold().monospacedDigit())
        }
    }
}

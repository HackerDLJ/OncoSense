import SwiftUI

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Overview", systemImage: "heart.text.square.fill") }
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "chart.xyaxis.line") }
            InsightView()
                .tabItem { Label("How it works", systemImage: "waveform.path.ecg") }
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    connectionCard

                    if let result = store.result {
                        statusCard(result)
                        metrics
                        signals(result)
                    } else {
                        emptyState
                    }

                    if let error = store.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.refresh()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ONCOSENSE")
                    .font(.title.bold())
                Text("Personal health pattern monitoring")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "applewatch")
                .font(.title2)
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(store.watchStatusText, systemImage: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch")
                .font(.subheadline.weight(.semibold))
            Text(store.isHealthConnected ? "Reading authorized Health data" : "Connect Apple Health to start using real measurements.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Button(store.isHealthConnected ? "Refresh data" : "Connect Apple Health") {
                    if store.isHealthConnected {
                        Task { await store.refresh() }
                    } else {
                        store.connectHealth()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isRefreshing)

                if store.isRefreshing {
                    ProgressView()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statusCard(_ result: ScreeningResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CURRENT PATTERN")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text(result.state.title)
                    .font(.system(size: 34, weight: .black))
                Spacer()
                Text("\(result.signal)")
                    .font(.title.bold().monospacedDigit())
            }
            Text(result.summary)
                .foregroundStyle(.secondary)
            if let date = store.lastSnapshot?.timestamp {
                Text("Last measured \(date, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            MetricCard(title: "Persistence", value: "\(store.result?.persistenceDays ?? 0)d")
            MetricCard(title: "Data quality", value: "\(store.result?.dataQuality ?? 0)%")
        }
    }

    private func signals(_ result: ScreeningResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEASURED SIGNALS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(result.contributors.enumerated()), id: \.offset) { _, item in
                Label(item, systemImage: icon(for: item))
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
            Text("Building your personal baseline")
                .font(.title3.bold())
            Text("OncoSense needs at least two real HealthKit snapshots before it calculates a change score. No demo values are used.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func icon(for item: String) -> String {
        if item.contains("heart") { return "heart.fill" }
        if item.contains("variability") { return "waveform.path.ecg" }
        if item.contains("Respiratory") { return "lungs.fill" }
        if item.contains("Sleep") { return "moon.fill" }
        if item.contains("Activity") { return "figure.walk" }
        return "waveform.path"
    }
}

private struct TimelineView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            List {
                if store.snapshots.isEmpty {
                    ContentUnavailableView("No measurements yet", systemImage: "heart.text.square", description: Text("Connect Apple Health and refresh to collect your first real snapshot."))
                } else {
                    Section("Recent measurements") {
                        ForEach(store.snapshots.prefix(30)) { snapshot in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(snapshot.timestamp, style: .date)
                                    Spacer()
                                    Text(snapshot.timestamp, style: .time)
                                }
                                Text(metricsText(snapshot))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(snapshot.source)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .refreshable { await store.refresh() }
        }
    }

    private func metricsText(_ s: HealthSnapshot) -> String {
        var values: [String] = []
        if let value = s.restingHeartRate { values.append("RHR \(Int(value)) bpm") }
        if let value = s.hrv { values.append("HRV \(Int(value)) ms") }
        if let value = s.respiratoryRate { values.append("Resp \(value, specifier: "%.1f")/min") }
        if let value = s.temperature { values.append("Temp \(value, specifier: "%.2f")°C") }
        if let value = s.sleepHours { values.append("Sleep \(value, specifier: "%.1f")h") }
        if let value = s.activityMinutes { values.append("Exercise \(Int(value))m") }
        return values.isEmpty ? "No authorized measurements available" : values.joined(separator: " · ")
    }
}

private struct InsightView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How OncoSense works")
                        .font(.largeTitle.bold())
                    Text("OncoSense reads the Health data you authorize, stores timestamped measurements on-device, and compares new measurements with your personal history.")
                        .foregroundStyle(.secondary)
                    InfoRow(title: "Data source", value: store.isHealthConnected ? "Apple Health / HealthKit" : "Not connected")
                    InfoRow(title: "Watch link", value: store.watchStatusText)
                    InfoRow(title: "Measurements", value: "\(store.snapshots.count)")
                    InfoRow(title: "Latest sync", value: store.sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "None")
                    Text("The pattern score is a research monitoring feature. It does not diagnose cancer. Persistent or concerning changes should be assessed by a qualified clinician.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("How it works")
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack { Text(title); Spacer(); Text(value).bold().multilineTextAlignment(.trailing) }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

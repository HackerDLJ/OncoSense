import SwiftUI
import Foundation

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()

    var body: some Scene {
        WindowGroup {
            if store.isOnboardingComplete {
                DashboardView()
                    .environmentObject(store)
            } else {
                OnboardingView()
                    .environmentObject(store)
            }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var page = 0
    @State private var isSettingUp = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.25), .cyan.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("ONCOSENSE")
                        .font(.headline.bold().tracking(2))
                    Spacer()
                    Text("Setup")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                TabView(selection: $page) {
                    OnboardingPage(icon: "waveform.path.ecg", title: "Know your baseline", body: "OncoSense turns the Health data you authorize into a longitudinal picture of how your body normally behaves.", detail: "It looks for persistent changes over time, not one isolated number.")
                        .tag(0)
                    OnboardingPage(icon: "heart.text.square.fill", title: "Use real measurements", body: "Heart rate, resting heart rate, HRV, respiratory rate, wrist temperature, sleep, exercise, steps, active energy and weight can be read from Apple Health when available.", detail: "If a signal is unavailable or you do not grant access, OncoSense shows that gap instead of inventing a value.")
                        .tag(1)
                    OnboardingPage(icon: "applewatch", title: "Bring your Watch into the loop", body: "The Apple Watch can collect health signals and pass snapshots to the iPhone through WatchConnectivity.", detail: "Queued transfer is used when the Watch is temporarily unreachable, so the two apps do not depend on being open together.")
                        .tag(2)
                    OnboardingPage(icon: "person.text.rectangle", title: "Add human context", body: "Use the Care Check-in to record fatigue, appetite, pain, fever and notes alongside your wearable history.", detail: "These notes are local context. They are not converted into a cancer diagnosis.")
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    Button {
                        if page < 3 {
                            page += 1
                        } else {
                            isSettingUp = true
                            Task {
                                _ = await store.startSetup()
                                isSettingUp = false
                            }
                        }
                    } label: {
                        HStack {
                            if isSettingUp { ProgressView().tint(.white) }
                            Text(isSettingUp ? "Connecting…" : (page == 3 ? "Connect Apple Health & Start" : "Continue"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSettingUp)

                    if page > 0 && page < 3 {
                        Button("Back") { page -= 1 }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let body: String
    let detail: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 62, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(body)
                .font(.title3)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var showingWatch = false

    var body: some View {
        TabView {
            HomeView(showingWatch: $showingWatch)
                .tabItem { Label("Today", systemImage: "heart.text.square.fill") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            CareView()
                .tabItem { Label("Care", systemImage: "person.text.rectangle") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "book.closed.fill") }
        }
        .sheet(isPresented: $showingWatch) {
            WatchConnectionView()
                .environmentObject(store)
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Binding var showingWatch: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    dataCoverage
                    signalGrid
                    patternCard
                    actionCard
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingWatch = true } label: {
                        Image(systemName: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch")
                    }
                    .accessibilityLabel("Apple Watch connection")
                }
            }
            .refreshable { await store.refresh() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR HEALTH PICTURE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("Know your baseline. Notice change.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("OncoSense combines real HealthKit measurements with your personal history. It is a pattern-monitoring tool, not a cancer diagnosis.")
                .foregroundStyle(.secondary)
        }
    }

    private var dataCoverage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(store.isHealthConnected ? "Apple Health connected" : "Apple Health not connected", systemImage: store.isHealthConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.headline)
                Spacer()
                Text("\(store.signalCoverage)%")
                    .font(.headline.monospacedDigit())
            }
            ProgressView(value: Double(store.signalCoverage), total: 100)
            Text("\(store.availableSignalCount) of 10 supported signals currently available. Missing data is shown as missing, never simulated.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(store.isHealthConnected ? "Refresh Health data" : "Connect Apple Health") {
                if store.isHealthConnected { Task { await store.refresh() } }
                else { store.connectHealth() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var signalGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIVE SIGNALS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                SignalCard(title: "Resting HR", value: store.lastSnapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill", note: "Personal baseline")
                SignalCard(title: "Heart rate", value: store.lastSnapshot?.heartRate.map { "\(Int($0)) bpm" }, icon: "waveform.path.ecg", note: "Latest available")
                SignalCard(title: "HRV", value: store.lastSnapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle", note: "Latest available")
                SignalCard(title: "Respiratory", value: store.lastSnapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill", note: "Latest available")
                SignalCard(title: "Wrist temp", value: store.lastSnapshot?.temperature.map { String(format: "%.2f°C", $0) }, icon: "thermometer.medium", note: "Sleep wrist temp")
                SignalCard(title: "Sleep", value: store.lastSnapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill", note: "Last 24h")
                SignalCard(title: "Steps", value: store.lastSnapshot?.steps.map { "\(Int($0))" }, icon: "figure.walk", note: "Last 24h")
                SignalCard(title: "Active energy", value: store.lastSnapshot?.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill", note: "Last 24h")
                SignalCard(title: "Exercise", value: store.lastSnapshot?.activityMinutes.map { "\(Int($0)) min" }, icon: "figure.run", note: "Last 24h")
                SignalCard(title: "Weight", value: store.lastSnapshot?.weightKg.map { String(format: "%.1f kg", $0) }, icon: "scalemass.fill", note: "Latest available")
            }
        }
    }

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERSONAL PATTERN")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if let result = store.result {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.state == .low ? "Close to baseline" : result.state == .watch ? "Change detected" : "Multiple changes")
                        .font(.title2.bold())
                    Spacer()
                    Text("\(result.signal)")
                        .font(.title.bold().monospacedDigit())
                }
                Text(result.summary)
                    .foregroundStyle(.secondary)
                Divider()
                ForEach(result.contributors.prefix(5), id: \.self) { item in
                    Label(item, systemImage: "waveform.path")
                        .font(.subheadline)
                }
                HStack {
                    Label("Data quality \(result.dataQuality)%", systemImage: "checkmark.shield")
                    Spacer()
                    Label("\(result.persistenceDays)d observed", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text("Baseline building")
                    .font(.title2.bold())
                Text("Collect several real measurements before interpreting a pattern. One reading is not enough.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Useful next steps", systemImage: "sparkles")
                .font(.headline)
            Text("Refresh after wearing your Watch, review Trends weekly, and use Care Check-in to record symptoms or notes that sensors cannot see.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Open Watch connection") { showingWatch = true }
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct SignalCard: View {
    let title: String
    let value: String?
    let icon: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value ?? "No data")
                .font(.title3.bold().monospacedDigit())
                .minimumScaleFactor(0.8)
            Text(value == nil ? "Permission or source unavailable" : note)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct TrendsView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Real measurements over time")
                        .font(.title2.bold())
                    Text("Each point is a snapshot collected from Apple Health. More frequent refreshes build a more useful personal history.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TrendCard(title: "Resting heart rate", unit: "bpm", values: store.snapshots.reversed().compactMap(\.restingHeartRate))
                    TrendCard(title: "HRV", unit: "ms", values: store.snapshots.reversed().compactMap(\.hrv))
                    TrendCard(title: "Respiratory rate", unit: "/min", values: store.snapshots.reversed().compactMap(\.respiratoryRate))
                    TrendCard(title: "Sleep", unit: "hours", values: store.snapshots.reversed().compactMap(\.sleepHours))
                    TrendCard(title: "Steps", unit: "steps", values: store.snapshots.reversed().compactMap(\.steps))
                    TrendCard(title: "Exercise", unit: "min", values: store.snapshots.reversed().compactMap(\.activityMinutes))

                    Text("Trend interpretation")
                        .font(.headline)
                    Text("OncoSense looks for persistent deviations from your own history. These charts are context, not diagnostic tests. A concerning pattern should be discussed with a qualified clinician.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Trends")
            .refreshable { await store.refresh() }
        }
    }
}

private struct TrendCard: View {
    let title: String
    let unit: String
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let last = values.last {
                    Text("\(last, specifier: "%.1f") \(unit)").font(.subheadline.bold().monospacedDigit())
                }
            }
            if values.count >= 2 {
                Sparkline(values: values)
                    .frame(height: 70)
            } else {
                Text("Collect more real measurements to reveal a trend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            }
            Text("\(values.count) observations")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct Sparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max(maxValue - minValue, 0.001)
            Path { path in
                for index in values.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let y = proxy.size.height - ((CGFloat(values[index] - minValue) / CGFloat(range)) * proxy.size.height)
                    if index == values.startIndex { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct WatchConnectionView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch")
                        .font(.system(size: 54))
                        .foregroundStyle(.tint)
                    Text("Apple Watch")
                        .font(.largeTitle.bold())
                    Text(store.watchStatusText)
                        .font(.headline)
                    statusRow("Session", store.sync.isActivated ? "Activated" : "Waiting")
                    statusRow("Reachability", store.sync.isReachable ? "Reachable now" : "Not reachable now")
                    statusRow("Queued transfers", "\(store.sync.pendingTransfers)")
                    statusRow("Last received", store.sync.lastReceived.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "None")
                    statusRow("Last sync", store.sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "None")

                    Button("Sync latest snapshot to Watch") {
                        store.syncLatestToWatch()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.lastSnapshot == nil)

                    Text("How it works")
                        .font(.headline)
                    Text("The Watch reads authorized HealthKit data and sends snapshots to the iPhone. The iPhone keeps the longer history and performs the longitudinal pattern analysis. If the Watch is temporarily unreachable, WatchConnectivity can queue user-info transfers for delivery later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Watch link")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold().multilineTextAlignment(.trailing)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct LearnView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            List {
                Section("What OncoSense does") {
                    Text("It collects authorized HealthKit measurements, keeps a timestamped personal history, compares recent measurements with that history, and highlights persistent changes.")
                    Text("It can also receive Watch snapshots through WatchConnectivity and keep them with the iPhone history.")
                }
                Section("What it does not do") {
                    Text("A wearable pattern is not a cancer diagnosis. OncoSense should not replace established cancer screening, diagnostic tests, or clinical care.")
                }
                Section("Why the app asks for this data") {
                    InfoRow(title: "HealthKit", value: store.isHealthConnected ? "Connected" : "Not connected")
                    InfoRow(title: "Signals available", value: "\(store.availableSignalCount)/10")
                    InfoRow(title: "Watch", value: store.watchStatusText)
                    InfoRow(title: "Stored observations", value: "\(store.snapshots.count)")
                }
                Section("Reset") {
                    Button("Show setup walkthrough again") { store.resetOnboarding() }
                }
            }
            .navigationTitle("Learn")
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack { Text(title); Spacer(); Text(value).bold().multilineTextAlignment(.trailing) }
    }
}

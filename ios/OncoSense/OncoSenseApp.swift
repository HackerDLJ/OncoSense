import SwiftUI
import Foundation

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()

    var body: some Scene {
        WindowGroup {
            if store.isOnboardingComplete {
                DashboardView().environmentObject(store)
            } else {
                OnboardingView().environmentObject(store)
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
            VStack(spacing: 20) {
                HStack {
                    Text("ONCOSENSE").font(.headline.bold()).tracking(2)
                    Spacer()
                    Text("Setup").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                TabView(selection: $page) {
                    OnboardingPage(icon: "waveform.path.ecg", title: "Know your baseline", message: "OncoSense builds a longitudinal picture from the Health data you authorize.", detail: "It looks for persistent changes over time, not one isolated number.").tag(0)
                    OnboardingPage(icon: "heart.text.square.fill", title: "Use real measurements", message: "Heart, sleep, activity, temperature and other supported HealthKit signals are shown only when real data is available.", detail: "Missing data stays missing. OncoSense never invents a measurement.").tag(1)
                    OnboardingPage(icon: "applewatch", title: "Connect your Watch", message: "Your Apple Watch can contribute HealthKit snapshots and sync them to the iPhone through WatchConnectivity.", detail: "The iPhone keeps the longer history and handles longitudinal analysis.").tag(2)
                    OnboardingPage(icon: "person.text.rectangle", title: "Add human context", message: "Record symptoms and notes that sensors cannot measure, alongside your physiological history.", detail: "These observations provide context and are not converted into a cancer diagnosis.").tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                VStack(spacing: 10) {
                    Button {
                        if page < 3 { page += 1 }
                        else {
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
                        Button("Back") { page -= 1 }.font(.footnote).foregroundStyle(.secondary)
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
    let message: String
    let detail: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 62, weight: .medium)).symbolRenderingMode(.hierarchical).foregroundStyle(.tint)
            Text(title).font(.system(size: 30, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text(message).font(.title3).multilineTextAlignment(.center)
            Text(detail).font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var showingWatch = false

    var body: some View {
        TabView {
            HomeView(showingWatch: $showingWatch).tabItem { Label("Today", systemImage: "heart.text.square.fill") }
            TrendsView().tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            CareView().tabItem { Label("Care", systemImage: "person.text.rectangle") }
            LearnView().tabItem { Label("Learn", systemImage: "book.closed.fill") }
        }
        .sheet(isPresented: $showingWatch) { WatchConnectionView().environmentObject(store) }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Binding var showingWatch: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR HEALTH PICTURE").font(.caption.bold()).foregroundStyle(.secondary)
                        Text("Know your baseline. Notice change.").font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("Real HealthKit measurements, your personal history, and explainable pattern changes in one place.").foregroundStyle(.secondary)
                    }
                    coverageCard
                    signalGrid
                    patternCard
                    Button("Open Apple Watch connection") { showingWatch = true }.buttonStyle(.bordered)
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

    private var coverageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(store.isHealthConnected ? "Apple Health connected" : "Apple Health not connected", systemImage: store.isHealthConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.headline)
                Spacer()
                Text("\(store.signalCoverage)%").font(.headline.monospacedDigit())
            }
            ProgressView(value: Double(store.signalCoverage), total: 100)
            Text("\(store.availableSignalCount) of 10 supported signals currently available. Missing data is never simulated.")
                .font(.footnote).foregroundStyle(.secondary)
            Button(store.isHealthConnected ? "Refresh Health data" : "Connect Apple Health") {
                if store.isHealthConnected { Task { await store.refresh() } } else { store.connectHealth() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var signalGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REAL SIGNALS").font(.caption.bold()).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                SignalCard(title: "Resting HR", value: store.lastSnapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, icon: "heart.fill", note: "Personal baseline")
                SignalCard(title: "Heart rate", value: store.lastSnapshot?.heartRate.map { "\(Int($0)) bpm" }, icon: "waveform.path.ecg", note: "Latest")
                SignalCard(title: "HRV", value: store.lastSnapshot?.hrv.map { "\(Int($0)) ms" }, icon: "waveform.path.ecg.rectangle", note: "Latest")
                SignalCard(title: "Respiratory", value: store.lastSnapshot?.respiratoryRate.map { String(format: "%.1f/min", $0) }, icon: "lungs.fill", note: "Latest")
                SignalCard(title: "Wrist temp", value: store.lastSnapshot?.temperature.map { String(format: "%.2f°C", $0) }, icon: "thermometer.medium", note: "Sleep wrist temp")
                SignalCard(title: "Sleep", value: store.lastSnapshot?.sleepHours.map { String(format: "%.1fh", $0) }, icon: "moon.fill", note: "Last 24h")
                SignalCard(title: "Steps", value: store.lastSnapshot?.steps.map { "\(Int($0))" }, icon: "figure.walk", note: "Last 24h")
                SignalCard(title: "Energy", value: store.lastSnapshot?.activeEnergy.map { "\(Int($0)) kcal" }, icon: "flame.fill", note: "Last 24h")
                SignalCard(title: "Exercise", value: store.lastSnapshot?.activityMinutes.map { "\(Int($0)) min" }, icon: "figure.run", note: "Last 24h")
                SignalCard(title: "Weight", value: store.lastSnapshot?.weightKg.map { String(format: "%.1f kg", $0) }, icon: "scalemass.fill", note: "Latest")
            }
        }
    }

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERSONAL PATTERN").font(.caption.bold()).foregroundStyle(.secondary)
            if let result = store.result {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.state == .low ? "Close to baseline" : result.state == .watch ? "Change detected" : "Multiple changes").font(.title2.bold())
                    Spacer()
                    Text("\(result.signal)").font(.title.bold().monospacedDigit())
                }
                Text(result.summary).foregroundStyle(.secondary)
                ForEach(result.contributors.prefix(5), id: \.self) { item in Label(item, systemImage: "waveform.path").font(.subheadline) }
                HStack {
                    Label("Data quality \(result.dataQuality)%", systemImage: "checkmark.shield")
                    Spacer()
                    Label("\(result.persistenceDays)d observed", systemImage: "calendar")
                }.font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Baseline building").font(.title2.bold())
                Text("Collect several real measurements before interpreting a pattern. One reading is not enough.").foregroundStyle(.secondary)
            }
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct SignalCard: View {
    let title: String
    let value: String?
    let icon: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(value ?? "No data").font(.title3.bold().monospacedDigit()).minimumScaleFactor(0.8)
            Text(value == nil ? "Permission or source unavailable" : note).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct TrendsView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Real measurements over time").font(.title2.bold())
                    Text("Each observation comes from Apple Health. More observations make personal trends more informative.").font(.footnote).foregroundStyle(.secondary)
                    TrendCard(title: "Resting heart rate", unit: "bpm", values: store.snapshots.reversed().compactMap(\.restingHeartRate))
                    TrendCard(title: "HRV", unit: "ms", values: store.snapshots.reversed().compactMap(\.hrv))
                    TrendCard(title: "Respiratory rate", unit: "/min", values: store.snapshots.reversed().compactMap(\.respiratoryRate))
                    TrendCard(title: "Sleep", unit: "hours", values: store.snapshots.reversed().compactMap(\.sleepHours))
                    TrendCard(title: "Steps", unit: "steps", values: store.snapshots.reversed().compactMap(\.steps))
                    TrendCard(title: "Exercise", unit: "min", values: store.snapshots.reversed().compactMap(\.activityMinutes))
                    Text("Trend interpretation").font(.headline)
                    Text("OncoSense highlights persistent deviations from your own history. These charts are context, not diagnostic tests. Discuss concerning changes with a qualified clinician.").font(.footnote).foregroundStyle(.secondary)
                }.padding()
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
                if let last = values.last { Text("\(last, specifier: "%.1f") \(unit)").font(.subheadline.bold().monospacedDigit()) }
            }
            if values.count >= 2 { Sparkline(values: values).frame(height: 70) }
            else { Text("Collect more real measurements to reveal a trend").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 70, alignment: .leading) }
            Text("\(values.count) observations").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct Sparkline: View {
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard let min = values.min(), let max = values.max(), values.count > 1 else { return }
                let range = max - min == 0 ? 1 : max - min
                for index in values.indices {
                    let x = geo.size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let y = geo.size.height - ((CGFloat(values[index] - min) / CGFloat(range)) * geo.size.height)
                    if index == values.startIndex { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

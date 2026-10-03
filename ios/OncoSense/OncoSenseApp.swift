import SwiftUI
import Foundation

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()

    var body: some Scene {
        WindowGroup {
            if store.isOnboardingComplete {
                MainShell().environmentObject(store)
            } else {
                OnboardingView().environmentObject(store)
            }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var page = 0
    @State private var connecting = false

    private let pages = [
        ("waveform.path.ecg", "Understand your normal", "OncoSense builds a personal baseline from the health data you authorize. Your normal is the reference point."),
        ("heart.text.square.fill", "See the real signals", "Heart rate, HRV, breathing, sleep, wrist temperature, activity and other supported HealthKit measurements appear only when real data exists."),
        ("applewatch", "Use iPhone + Watch together", "Your Watch can collect and transfer a current HealthKit snapshot. Your iPhone keeps the longer history and context."),
        ("person.crop.circle.badge.checkmark", "Turn change into context", "Track symptoms and notes beside your measurements. OncoSense highlights patterns for discussion, not a cancer diagnosis.")
    ]

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            LinearGradient(colors: [.blue.opacity(0.20), .purple.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Label("ONCOSENSE", systemImage: "waveform.path.ecg").font(.headline.bold())
                    Spacer()
                    Text("\(page + 1)/4").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: pages[page].0)
                    .font(.system(size: 64, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                Text(pages[page].1)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(pages[page].2)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule().fill(index == page ? Color.accentColor : Color.secondary.opacity(0.2)).frame(width: index == page ? 24 : 7, height: 7)
                    }
                }

                Button {
                    if page < 3 {
                        withAnimation { page += 1 }
                    } else {
                        connecting = true
                        Task {
                            _ = await store.startSetup()
                            connecting = false
                        }
                    }
                } label: {
                    HStack {
                        if connecting { ProgressView().tint(.white) }
                        Text(connecting ? "Connecting…" : page == 3 ? "Connect Apple Health" : "Continue")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(connecting)

                if page > 0 && page < 3 {
                    Button("Back") { withAnimation { page -= 1 } }.font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
    }
}

struct MainShell: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var showWatch = false

    var body: some View {
        TabView {
            OverviewView(showWatch: $showWatch).tabItem { Label("Overview", systemImage: "house.fill") }
            SignalsView().tabItem { Label("Signals", systemImage: "waveform.path.ecg") }
            TrendsView().tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            CareView().tabItem { Label("Care", systemImage: "person.text.rectangle") }
        }
        .sheet(isPresented: $showWatch) { WatchConnectionView().environmentObject(store) }
    }
}

private struct OverviewView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Binding var showWatch: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    dataReadiness
                    pattern
                    nextStep
                }
                .padding()
            }
            .navigationTitle("OncoSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showWatch = true } label: {
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
            Text("YOUR HEALTH PICTURE").font(.caption.bold()).foregroundStyle(.secondary)
            Text("Know your normal. Notice what changes.").font(.system(size: 31, weight: .bold, design: .rounded))
            Text("A longitudinal view of your real Apple Health data, your personal baseline and the context you add yourself.").foregroundStyle(.secondary)
        }
    }

    private var dataReadiness: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(store.isHealthConnected ? "Apple Health connected" : "Apple Health needs permission", systemImage: store.isHealthConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.headline)
                Spacer()
                Text("\(store.availableSignalCount)/10").font(.headline.monospacedDigit())
            }
            ProgressView(value: Double(store.signalCoverage), total: 100)
            Text("Signal coverage is based on real values available right now. A missing value is shown as missing, never guessed.")
                .font(.caption).foregroundStyle(.secondary)
            Button(store.isHealthConnected ? "Refresh real data" : "Connect Apple Health") {
                if store.isHealthConnected { Task { await store.refresh() } } else { store.connectHealth() }
            }
            .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }

    private var pattern: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PERSONAL PATTERN").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if let result = store.result { Text("Quality \(result.dataQuality)%").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            }
            if let result = store.result {
                Text(result.state == .low ? "Close to your baseline" : result.state == .watch ? "Worth watching" : "Repeated change")
                    .font(.title2.bold())
                Text(result.summary).foregroundStyle(.secondary)
                ForEach(result.contributors.prefix(4), id: \.self) { contributor in
                    Label(contributor, systemImage: "waveform.path").font(.subheadline)
                }
                Divider()
                HStack {
                    Label("\(result.persistenceDays) observed day(s)", systemImage: "calendar")
                    Spacer()
                    Text("Updated \(result.generatedAt, style: .relative) ago").font(.caption)
                }
                .font(.caption).foregroundStyle(.secondary)
            } else {
                Label("Baseline building", systemImage: "hourglass").font(.title3.bold())
                Text("OncoSense waits for enough real observations before interpreting a pattern. This is deliberate: one measurement is not a trend.").foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private var nextStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT TO DO NEXT").font(.caption.bold()).foregroundStyle(.secondary)
            ActionRow(icon: "applewatch", title: "Check Watch connection", detail: store.watchStatusText) { showWatch = true }
            ActionRow(icon: "person.text.rectangle", title: "Add today's context", detail: "Fatigue, appetite, pain, fever and notes") { }
            ActionRow(icon: "book.closed", title: "Learn how to read your data", detail: "Understand baseline, coverage and pattern changes") { }
        }
        .cardStyle()
    }
}

private struct SignalsView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            List {
                Section("Physiology") {
                    SignalDetail(title: "Resting heart rate", value: store.lastSnapshot?.restingHeartRate.map { "\(Int($0)) bpm" }, subtitle: "Latest available HealthKit value", icon: "heart.fill")
                    SignalDetail(title: "Heart rate", value: store.lastSnapshot?.heartRate.map { "\(Int($0)) bpm" }, subtitle: "Latest available HealthKit value", icon: "waveform.path.ecg")
                    SignalDetail(title: "Heart-rate variability", value: store.lastSnapshot?.hrv.map { "\(Int($0)) ms" }, subtitle: "SDNN, latest available value", icon: "waveform.path.ecg.rectangle")
                    SignalDetail(title: "Respiratory rate", value: store.lastSnapshot?.respiratoryRate.map { String(format: "%.1f /min", $0) }, subtitle: "Latest available HealthKit value", icon: "lungs.fill")
                    SignalDetail(title: "Sleeping wrist temperature", value: store.lastSnapshot?.temperature.map { String(format: "%.2f °C", $0) }, subtitle: "Latest available value", icon: "thermometer.medium")
                }
                Section("Recovery & activity") {
                    SignalDetail(title: "Sleep", value: store.lastSnapshot?.sleepHours.map { String(format: "%.1f h", $0) }, subtitle: "Sleep analysis in the last 24 hours", icon: "moon.fill")
                    SignalDetail(title: "Exercise", value: store.lastSnapshot?.activityMinutes.map { "\(Int($0)) min" }, subtitle: "Apple Exercise time in the last 24 hours", icon: "figure.run")
                    SignalDetail(title: "Steps", value: store.lastSnapshot?.steps.map { "\(Int($0))" }, subtitle: "Last 24 hours", icon: "figure.walk")
                    SignalDetail(title: "Active energy", value: store.lastSnapshot?.activeEnergy.map { "\(Int($0)) kcal" }, subtitle: "Last 24 hours", icon: "flame.fill")
                    SignalDetail(title: "Weight", value: store.lastSnapshot?.weightKg.map { String(format: "%.1f kg", $0) }, subtitle: "Latest available HealthKit value", icon: "scalemass.fill")
                }
                Section {
                    Text("All values come from authorized HealthKit sources. Availability depends on your devices, permissions and connected data sources.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Signals")
            .refreshable { await store.refresh() }
        }
    }
}

private struct SignalDetail: View {
    let title: String
    let value: String?
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(value ?? "No data")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
        .padding(.vertical, 4)
    }
}

private struct TrendsView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your history, not a population average")
                        .font(.title2.bold())
                    Text("These lines use the observations OncoSense has actually collected. More regular observations make your personal baseline more useful.")
                        .font(.footnote).foregroundStyle(.secondary)
                    TrendCard(title: "Resting heart rate", unit: "bpm", values: store.snapshots.reversed().compactMap(\.restingHeartRate))
                    TrendCard(title: "HRV", unit: "ms", values: store.snapshots.reversed().compactMap(\.hrv))
                    TrendCard(title: "Respiratory rate", unit: "/min", values: store.snapshots.reversed().compactMap(\.respiratoryRate))
                    TrendCard(title: "Sleep", unit: "hours", values: store.snapshots.reversed().compactMap(\.sleepHours))
                    TrendCard(title: "Exercise", unit: "min", values: store.snapshots.reversed().compactMap(\.activityMinutes))
                    TrendCard(title: "Steps", unit: "steps", values: store.snapshots.reversed().compactMap(\.steps))
                    Text("Important")
                        .font(.headline)
                    Text("A trend or pattern change can have many causes. OncoSense is not a diagnostic test and does not determine whether someone has cancer. Persistent or concerning changes should be discussed with a qualified clinician.")
                        .font(.footnote).foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let last = values.last { Text("\(last, specifier: "%.1f") \(unit)").font(.subheadline.bold().monospacedDigit()) }
            }
            if values.count > 1 {
                Sparkline(values: values).frame(height: 64)
            } else {
                Text("Waiting for more real observations").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            }
            Text("\(values.count) observation(s)").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
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
                    let y = geo.size.height - CGFloat((values[index] - min) / range) * geo.size.height
                    if index == values.startIndex { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct ActionRow: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func cardStyle() -> some View {
        self.padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

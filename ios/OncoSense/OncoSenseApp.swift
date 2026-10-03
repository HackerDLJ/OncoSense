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
            VStack(spacing: 0) {
                HStack {
                    Label("ONCOSENSE", systemImage: "waveform.path.ecg").font(.headline.bold())
                    Spacer()
                    Text("\(page + 1)/\(pages.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24).padding(.top, 20)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 18) {
                            Spacer(minLength: 16)
                            Image(systemName: pages[index].0).font(.system(size: 64, weight: .medium)).symbolRenderingMode(.hierarchical).foregroundStyle(.tint)
                            Text(pages[index].1).font(.system(size: 32, weight: .bold, design: .rounded)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            Text(pages[index].2).font(.body).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal, 12).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 16)
                        }
                        .padding(.horizontal, 24).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule().fill(index == page ? Color.accentColor : Color.secondary.opacity(0.2)).frame(width: index == page ? 24 : 7, height: 7)
                    }
                }.padding(.bottom, 18)

                VStack(spacing: 10) {
                    Button {
                        if page < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.22)) { page += 1 }
                        } else {
                            connecting = true
                            Task {
                                let success = await store.startSetup()
                                await MainActor.run { connecting = false; _ = success }
                            }
                        }
                    } label: {
                        HStack { if connecting { ProgressView().tint(.white) }; Text(connecting ? "Connecting…" : page == pages.count - 1 ? "Connect Apple Health" : "Continue") }
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent).disabled(connecting)

                    if page > 0 {
                        Button("Back") { withAnimation(.easeInOut(duration: 0.22)) { page -= 1 } }.font(.footnote.weight(.medium)).foregroundStyle(.secondary).disabled(connecting)
                    } else {
                        Text("Swipe to explore").font(.footnote).foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
        .interactiveDismissDisabled(connecting)
    }
}

private enum AppTab: Hashable { case overview, signals, trends, care }

struct MainShell: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var selectedTab: AppTab = .overview
    @State private var showWatch = false
    @State private var showLearn = false

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView(showWatch: $showWatch, onSelectCare: { selectedTab = .care }, onShowLearn: { showLearn = true })
                .tabItem { Label("Overview", systemImage: "house.fill") }.tag(AppTab.overview)
            SignalsView().tabItem { Label("Signals", systemImage: "waveform.path.ecg") }.tag(AppTab.signals)
            TrendsView().tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }.tag(AppTab.trends)
            CareView().tabItem { Label("Care", systemImage: "person.text.rectangle") }.tag(AppTab.care)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showWatch) { WatchConnectionView().environmentObject(store) }
        .sheet(isPresented: $showLearn) { LearnView() }
    }
}

private struct OverviewView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Binding var showWatch: Bool
    let onSelectCare: () -> Void
    let onShowLearn: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) { hero; dataReadiness; pattern; nextStep }
                    .padding().padding(.bottom, 12)
            }
            .navigationTitle("OncoSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showWatch = true } label: { Image(systemName: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch") }
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
                Label(store.isHealthConnected ? "Apple Health connected" : "Apple Health needs permission", systemImage: store.isHealthConnected ? "checkmark.circle.fill" : "exclamationmark.circle").font(.headline)
                Spacer(); Text("\(store.availableSignalCount)/10").font(.headline.monospacedDigit())
            }
            ProgressView(value: Double(store.signalCoverage), total: 100)
            Text("Signal coverage is based on real values available right now. A missing value is shown as missing, never guessed.").font(.caption).foregroundStyle(.secondary)
            Button(store.isHealthConnected ? "Refresh real data" : "Connect Apple Health") {
                if store.isHealthConnected { Task { await store.refresh() } } else { store.connectHealth() }
            }.buttonStyle(.borderedProminent)
        }.cardStyle()
    }

    private var pattern: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("PERSONAL PATTERN").font(.caption.bold()).foregroundStyle(.secondary); Spacer(); if let result = store.result { Text("Quality \(result.dataQuality)%").font(.caption.monospacedDigit()).foregroundStyle(.secondary) } }
            if let result = store.result {
                Text(result.state == .low ? "Close to your baseline" : result.state == .watch ? "Worth watching" : "Repeated change").font(.title2.bold())
                Text(result.summary).foregroundStyle(.secondary)
                ForEach(result.contributors.prefix(4), id: \.self) { Label($0, systemImage: "waveform.path").font(.subheadline) }
                Divider()
                HStack { Label("\(result.persistenceDays) observed day(s)", systemImage: "calendar"); Spacer(); Text("Updated \(result.generatedAt, style: .relative) ago").font(.caption) }.font(.caption).foregroundStyle(.secondary)
            } else {
                Label("Baseline building", systemImage: "hourglass").font(.title3.bold())
                Text("OncoSense waits for enough real observations before interpreting a pattern. One measurement is not a trend.").foregroundStyle(.secondary)
            }
        }.cardStyle()
    }

    private var nextStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT TO DO NEXT").font(.caption.bold()).foregroundStyle(.secondary)
            ActionRow(icon: "applewatch", title: "Check Watch connection", detail: store.watchStatusText) { showWatch = true }
            ActionRow(icon: "person.text.rectangle", title: "Add today's context", detail: "Fatigue, appetite, pain, fever and notes") { onSelectCare() }
            ActionRow(icon: "book.closed", title: "Learn how to read your data", detail: "Understand baseline, coverage and pattern changes") { onShowLearn() }
        }.cardStyle()
    }
}

private struct SignalsView: View {
    @EnvironmentObject private var store: OncoSenseStore
    private let physiology: [SignalMetric] = [.restingHeartRate, .heartRate, .hrv, .respiratoryRate, .temperature]
    private let recovery: [SignalMetric] = [.sleep, .exercise, .steps, .activeEnergy, .weight]

    var body: some View {
        NavigationStack {
            List {
                Section("Physiology") { ForEach(physiology) { metric in SignalRow(metric: metric, snapshot: store.lastSnapshot) } }
                Section("Recovery & activity") { ForEach(recovery) { metric in SignalRow(metric: metric, snapshot: store.lastSnapshot) } }
                Section {
                    Text("Tap any signal for its latest value, your personal baseline, direction of change, data coverage and a plain-language explanation. Insights describe your data only and are not a diagnosis.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Signals")
            .refreshable { await store.refresh() }
        }
    }
}

private struct SignalRow: View {
    let metric: SignalMetric
    let snapshot: HealthSnapshot?
    var body: some View {
        NavigationLink {
            SignalInsightView(metric: metric, snapshots: [snapshot].compactMap { $0 })
        } label: {
            HStack(spacing: 12) {
                Image(systemName: metric.icon).font(.title3).frame(width: 30).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(metric.title).font(.subheadline.weight(.semibold))
                    Text(metric.shortDescription).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(metric.formatted(metric.value(from: snapshot)))
                    .font(.subheadline.bold().monospacedDigit()).foregroundStyle(metric.value(from: snapshot) == nil ? .secondary : .primary)
            }.padding(.vertical, 4)
        }
    }
}

private struct TrendsView: View {
    @EnvironmentObject private var store: OncoSenseStore
    private let metrics: [SignalMetric] = [.restingHeartRate, .hrv, .respiratoryRate, .sleep, .exercise, .steps, .temperature, .weight]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your history, not a population average").font(.title2.bold())
                        Text("Tap a trend to understand what your own observations are doing over time. More regular observations make the personal baseline more useful.").font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    ForEach(metrics) { metric in
                        NavigationLink {
                            SignalInsightView(metric: metric, snapshots: store.snapshots)
                        } label: {
                            TrendCard(metric: metric, snapshots: store.snapshots)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Important").font(.headline)
                        Text("A trend or pattern change can have many causes. OncoSense is not a diagnostic test and does not determine whether someone has cancer. Persistent or concerning changes should be discussed with a qualified clinician.").font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }.padding()
            }
            .navigationTitle("Trends")
            .refreshable { await store.refresh() }
        }
    }
}

private struct TrendCard: View {
    let metric: SignalMetric
    let snapshots: [HealthSnapshot]

    private var values: [Double] { snapshots.sorted { $0.timestamp < $1.timestamp }.suffix(60).compactMap { metric.value(from: $0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(metric.title, systemImage: metric.icon).font(.headline)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
            HStack(alignment: .bottom) {
                Text(metric.formatted(values.last)).font(.title3.bold().monospacedDigit())
                if let change = metric.percentChange(values) {
                    Text(change >= 0 ? "+\(Int(change))%" : "\(Int(change))%")
                        .font(.caption.bold().monospacedDigit()).foregroundStyle(change == 0 ? .secondary : .tint)
                }
                Spacer()
                Text("\(values.count) points").font(.caption).foregroundStyle(.secondary)
            }
            Sparkline(values: values).frame(height: 54)
            Text(metric.shortDescription).font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.primary.opacity(0.06)))
    }
}

private struct SignalInsightView: View {
    let metric: SignalMetric
    let snapshots: [HealthSnapshot]

    private var values: [Double] { snapshots.sorted { $0.timestamp < $1.timestamp }.suffix(90).compactMap { metric.value(from: $0) } }
    private var baseline: Double? { values.isEmpty ? nil : values.reduce(0, +) / Double(values.count) }
    private var latest: Double? { values.last }
    private var change: Double? { metric.percentChange(values) }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                chartCard
                insightCard
                detailGrid
                explanation
            }.padding()
        }
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon).font(.system(size: 28, weight: .semibold)).foregroundStyle(.tint)
                VStack(alignment: .leading) { Text(metric.title).font(.title2.bold()); Text(metric.unitLabel).font(.subheadline).foregroundStyle(.secondary) }
            }
            Text(metric.longDescription).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR RECENT HISTORY").font(.caption.bold()).foregroundStyle(.secondary)
            Sparkline(values: values).frame(height: 130)
            HStack { Text("Oldest").font(.caption).foregroundStyle(.secondary); Spacer(); Text("Latest").font(.caption).foregroundStyle(.secondary) }
        }.padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(insightTitle, systemImage: insightIcon).font(.headline)
            Text(insightText).font(.subheadline)
            Text("This is a description of your recorded data, not a medical diagnosis.").font(.caption).foregroundStyle(.secondary)
        }.padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            InsightTile(title: "Latest", value: metric.formatted(latest), icon: "scope")
            InsightTile(title: "Your average", value: metric.formatted(baseline), icon: "minus")
            InsightTile(title: "Change", value: change.map { String(format: "%+.1f%%", $0) } ?? "Not enough data", icon: "arrow.up.right")
            InsightTile(title: "Observations", value: "\(values.count)", icon: "chart.bar")
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to read this").font(.headline)
            Text(metric.insightGuidance).font(.subheadline).foregroundStyle(.secondary)
            Text("If a change is persistent, unexpected, or concerning, bring the trend and your Care notes to a qualified healthcare professional.").font(.footnote).foregroundStyle(.secondary)
        }.padding(.top, 4)
    }

    private var insightTitle: String {
        guard let latest, let baseline else { return "Collecting your baseline" }
        let delta = latest - baseline
        if abs(delta) < metric.meaningfulDifference(for: baseline) { return "Close to your personal average" }
        return delta > 0 ? "Above your recent average" : "Below your recent average"
    }

    private var insightIcon: String {
        guard let latest, let baseline else { return "hourglass" }
        return latest >= baseline ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
    }

    private var insightText: String {
        guard let latest, let baseline else { return "OncoSense needs more real observations before it can describe a personal pattern. Missing data is never filled with guesses." }
        let delta = latest - baseline
        let amount = metric.formatted(abs(delta))
        if abs(delta) < metric.meaningfulDifference(for: baseline) { return "Your latest recorded value is \(metric.formatted(latest)), which is close to your average of \(metric.formatted(baseline))." }
        return "Your latest recorded value is \(metric.formatted(latest)), about \(amount) \(delta > 0 ? "above" : "below") your personal average. Look at the full history and context rather than a single point."
    }
}

private struct InsightTile: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.tint)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold().monospacedDigit()).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct Sparkline: View {
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            if values.count > 1 {
                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 1
                let range = max(maxValue - minValue, 0.0001)
                Path { path in
                    for index in values.indices {
                        let x = geo.size.width * CGFloat(index) / CGFloat(values.count - 1)
                        let y = geo.size.height - ((CGFloat(values[index] - minValue) / CGFloat(range)) * geo.size.height)
                        if index == values.startIndex { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(.tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            } else {
                ContentUnavailableView("Not enough data", systemImage: "chart.xyaxis.line", description: Text("Keep collecting real HealthKit observations."))
            }
        }
    }
}

private enum SignalMetric: String, CaseIterable, Identifiable {
    case restingHeartRate, heartRate, hrv, respiratoryRate, temperature, sleep, exercise, steps, activeEnergy, weight
    var id: String { rawValue }
    var title: String {
        switch self { case .restingHeartRate: return "Resting heart rate"; case .heartRate: return "Heart rate"; case .hrv: return "Heart-rate variability"; case .respiratoryRate: return "Respiratory rate"; case .temperature: return "Sleeping wrist temperature"; case .sleep: return "Sleep"; case .exercise: return "Exercise"; case .steps: return "Steps"; case .activeEnergy: return "Active energy"; case .weight: return "Weight" }
    }
    var icon: String {
        switch self { case .restingHeartRate, .heartRate: return "heart.fill"; case .hrv: return "waveform.path.ecg.rectangle"; case .respiratoryRate: return "lungs.fill"; case .temperature: return "thermometer.medium"; case .sleep: return "moon.fill"; case .exercise: return "figure.run"; case .steps: return "figure.walk"; case .activeEnergy: return "flame.fill"; case .weight: return "scalemass.fill" }
    }
    var unitLabel: String {
        switch self { case .restingHeartRate, .heartRate: return "beats per minute"; case .hrv: return "milliseconds"; case .respiratoryRate: return "breaths per minute"; case .temperature: return "degrees Celsius"; case .sleep: return "hours"; case .exercise: return "minutes"; case .steps: return "steps"; case .activeEnergy: return "kilocalories"; case .weight: return "kilograms" }
    }
    var shortDescription: String {
        switch self { case .restingHeartRate: return "Your resting heart-rate reading"; case .heartRate: return "Latest heart-rate reading"; case .hrv: return "SDNN from Apple Health"; case .respiratoryRate: return "Latest breathing rate"; case .temperature: return "Wrist temperature when available"; case .sleep: return "Sleep in the latest 24-hour window"; case .exercise: return "Apple Exercise time"; case .steps: return "Steps in the latest 24-hour window"; case .activeEnergy: return "Active energy in the latest 24-hour window"; case .weight: return "Latest body-mass reading" }
    }
    var longDescription: String { shortDescription + ". OncoSense compares this measurement with your own recorded history rather than a diagnostic threshold." }
    var insightGuidance: String {
        switch self { case .restingHeartRate: return "Resting heart rate can vary with activity, recovery, stress, illness, medication and measurement conditions."; case .heartRate: return "Heart rate naturally changes with activity and context. A single reading is much less informative than repeated observations."; case .hrv: return "HRV is sensitive to sleep, stress, recovery and measurement conditions. Focus on your own pattern."; case .respiratoryRate: return "Breathing rate can vary with sleep, activity and illness. Use the longitudinal pattern as context."; case .temperature: return "Wrist temperature is not the same as a clinical body-temperature measurement and can vary with environment and wear conditions."; case .sleep: return "Sleep duration is one part of recovery and can vary from night to night."; case .exercise: return "Exercise time reflects recorded activity and can change with routine, recovery and device use."; case .steps: return "Step counts reflect recorded movement and are useful as an activity context signal."; case .activeEnergy: return "Active energy is an estimate from Apple Health and is best interpreted over repeated observations."; case .weight: return "Body mass can fluctuate for many reasons. Look for sustained patterns rather than a single measurement." }
    }
    func value(from snapshot: HealthSnapshot?) -> Double? {
        guard let snapshot else { return nil }
        switch self { case .restingHeartRate: return snapshot.restingHeartRate; case .heartRate: return snapshot.heartRate; case .hrv: return snapshot.hrv; case .respiratoryRate: return snapshot.respiratoryRate; case .temperature: return snapshot.temperature; case .sleep: return snapshot.sleepHours; case .exercise: return snapshot.activityMinutes; case .steps: return snapshot.steps; case .activeEnergy: return snapshot.activeEnergy; case .weight: return snapshot.weightKg }
    }
    func formatted(_ value: Double?) -> String {
        guard let value else { return "No data" }
        switch self { case .restingHeartRate, .heartRate: return "\(Int(value.rounded())) bpm"; case .hrv: return "\(Int(value.rounded())) ms"; case .respiratoryRate: return String(format: "%.1f /min", value); case .temperature: return String(format: "%.2f °C", value); case .sleep: return String(format: "%.1f h", value); case .exercise: return "\(Int(value.rounded())) min"; case .steps: return "\(Int(value.rounded()))"; case .activeEnergy: return "\(Int(value.rounded())) kcal"; case .weight: return String(format: "%.1f kg", value) }
    }
    func percentChange(_ values: [Double]) -> Double? { guard values.count >= 2, let first = values.first, first != 0, let last = values.last else { return nil }; return ((last - first) / abs(first)) * 100 }
    func meaningfulDifference(for baseline: Double) -> Double { max(abs(baseline) * 0.05, self == .temperature ? 0.05 : 0.5) }
}

private struct ActionRow: View {
    let icon: String; let title: String; let detail: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 34, height: 34).background(.tint.opacity(0.12), in: Circle()).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

private extension View {
    func cardStyle() -> some View { self.padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.primary.opacity(0.05))) }
}

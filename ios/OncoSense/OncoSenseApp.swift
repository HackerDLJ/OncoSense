import SwiftUI
import Foundation

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()
    var body: some Scene { WindowGroup { if store.isOnboardingComplete { MainShell().environmentObject(store) } else { OnboardingView().environmentObject(store) } } }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var page = 0
    @State private var connecting = false
    private let pages = [
        ("waveform.path.ecg", "Understand your normal", "OncoSense builds a personal baseline from the health data you authorize."),
        ("heart.text.square.fill", "See the real signals", "Real HealthKit measurements appear only when real data exists."),
        ("applewatch", "Use iPhone + Watch together", "Your Watch can collect and transfer a current HealthKit snapshot."),
        ("person.crop.circle.badge.checkmark", "Turn change into context", "Track symptoms and notes beside measurements. This is not a cancer diagnosis.")
    ]
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack { Label("ONCOSENSE", systemImage: "waveform.path.ecg").font(.headline.bold()); Spacer(); Text("\(page + 1)/\(pages.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }.padding(.horizontal, 24).padding(.top, 20)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 18) { Spacer(); Image(systemName: pages[i].0).font(.system(size: 64, weight: .medium)).symbolRenderingMode(.hierarchical).foregroundStyle(.tint); Text(pages[i].1).font(.system(size: 32, weight: .bold, design: .rounded)).multilineTextAlignment(.center); Text(pages[i].2).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 12); Spacer() }.padding(.horizontal, 24).tag(i)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 6) { ForEach(pages.indices, id: \.self) { i in Capsule().fill(i == page ? Color.accentColor : Color.secondary.opacity(0.2)).frame(width: i == page ? 24 : 7, height: 7) } }.padding(.bottom, 18)
                VStack(spacing: 10) {
                    Button {
                        if page < pages.count - 1 { withAnimation(.easeInOut(duration: 0.22)) { page += 1 } } else { connecting = true; Task { _ = await store.startSetup(); await MainActor.run { connecting = false } } }
                    } label: { HStack { if connecting { ProgressView().tint(.white) }; Text(connecting ? "Connecting…" : page == pages.count - 1 ? "Connect Apple Health" : "Continue") }.frame(maxWidth: .infinity).padding(.vertical, 4) }.buttonStyle(.borderedProminent).disabled(connecting)
                    if page > 0 { Button("Back") { withAnimation { page -= 1 } }.font(.footnote).foregroundStyle(.secondary) } else { Text("Swipe to explore").font(.footnote).foregroundStyle(.tertiary) }
                }.padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }
}

private enum AppTab: Hashable { case overview, signals, trends, care }

struct MainShell: View {
    @EnvironmentObject private var store: OncoSenseStore
    @State private var tab: AppTab = .overview
    @State private var showWatch = false
    @State private var showLearn = false
    var body: some View {
        TabView(selection: $tab) {
            OverviewView(showWatch: $showWatch, onSelectCare: { tab = .care }, onShowLearn: { showLearn = true }).tabItem { Label("Overview", systemImage: "house.fill") }.tag(AppTab.overview)
            SignalsView().tabItem { Label("Signals", systemImage: "waveform.path.ecg") }.tag(AppTab.signals)
            TrendsView().tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }.tag(AppTab.trends)
            CareView().tabItem { Label("Care", systemImage: "person.text.rectangle") }.tag(AppTab.care)
        }.toolbarBackground(.ultraThinMaterial, for: .tabBar).toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showWatch) { WatchConnectionView().environmentObject(store) }.sheet(isPresented: $showLearn) { LearnView() }
    }
}

private struct OverviewView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Binding var showWatch: Bool
    let onSelectCare: () -> Void
    let onShowLearn: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 18) { hero; dataReadiness; pattern; nextStep }.padding().padding(.bottom, 12) }
                .navigationTitle("OncoSense").toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showWatch = true } label: { Image(systemName: store.sync.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch") } } }.refreshable { await store.refresh() }
        }
    }
    private var hero: some View { VStack(alignment: .leading, spacing: 8) { Text("YOUR HEALTH PICTURE").font(.caption.bold()).foregroundStyle(.secondary); Text("Know your normal. Notice what changes.").font(.system(size: 31, weight: .bold, design: .rounded)); Text("A longitudinal view of your real Apple Health data, your personal baseline and the context you add yourself.").foregroundStyle(.secondary) } }
    private var dataReadiness: some View { VStack(alignment: .leading, spacing: 12) { HStack { Label(store.isHealthConnected ? "Apple Health connected" : "Apple Health needs permission", systemImage: store.isHealthConnected ? "checkmark.circle.fill" : "exclamationmark.circle").font(.headline); Spacer(); Text("\(store.availableSignalCount)/10").font(.headline.monospacedDigit()) }; ProgressView(value: Double(store.signalCoverage), total: 100); Text("Real values only. Missing measurements are never guessed.").font(.caption).foregroundStyle(.secondary); Button(store.isHealthConnected ? "Refresh real data" : "Connect Apple Health") { if store.isHealthConnected { Task { await store.refresh() } } else { store.connectHealth() } }.buttonStyle(.borderedProminent) }.cardStyle() }
    private var pattern: some View { VStack(alignment: .leading, spacing: 12) { HStack { Text("PERSONAL PATTERN").font(.caption.bold()).foregroundStyle(.secondary); Spacer(); if let r = store.result { Text("Quality \(r.dataQuality)%").font(.caption.monospacedDigit()).foregroundStyle(.secondary) } }; if let r = store.result { Text(r.state == .low ? "Close to your baseline" : r.state == .watch ? "Worth watching" : "Repeated change").font(.title2.bold()); Text(r.summary).foregroundStyle(.secondary); ForEach(r.contributors.prefix(4), id: \.self) { Label($0, systemImage: "waveform.path").font(.subheadline) } } else { Label("Baseline building", systemImage: "hourglass").font(.title3.bold()); Text("More real observations are needed before describing a personal pattern.").foregroundStyle(.secondary) } }.cardStyle() }
    private var nextStep: some View { VStack(alignment: .leading, spacing: 10) { Text("WHAT TO DO NEXT").font(.caption.bold()).foregroundStyle(.secondary); ActionRow(icon: "applewatch", title: "Check Watch connection", detail: store.watchStatusText) { showWatch = true }; ActionRow(icon: "person.text.rectangle", title: "Add today's context", detail: "Fatigue, appetite, pain, fever and notes") { onSelectCare() }; ActionRow(icon: "book.closed", title: "Learn how to read your data", detail: "Understand baseline, coverage and pattern changes") { onShowLearn() } }.cardStyle() }
}

private struct SignalsView: View {
    @EnvironmentObject private var store: OncoSenseStore
    private let metrics: [SignalMetric] = [.restingHeartRate, .heartRate, .hrv, .respiratoryRate, .temperature, .sleep, .exercise, .steps, .activeEnergy, .weight]
    var body: some View {
        NavigationStack { List { Section("Physiology") { ForEach(metrics.prefix(5)) { SignalRow(metric: $0) } }; Section("Recovery & activity") { ForEach(metrics.dropFirst(5)) { SignalRow(metric: $0) } }; Section { Text("Tap a signal for your latest value, personal baseline, direction, coverage and plain-language context. These insights describe recorded data only.").font(.footnote).foregroundStyle(.secondary) } }.listStyle(.insetGrouped).navigationTitle("Signals").refreshable { await store.refresh() } }
    }
}

private struct SignalRow: View {
    @EnvironmentObject private var store: OncoSenseStore
    let metric: SignalMetric
    var body: some View {
        NavigationLink { SignalInsightView(metric: metric) } label: {
            HStack(spacing: 12) { Image(systemName: metric.icon).font(.title3).frame(width: 30).foregroundStyle(.tint); VStack(alignment: .leading, spacing: 3) { Text(metric.title).font(.subheadline.weight(.semibold)); Text(metric.shortDescription).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(metric.formatted(metric.value(from: store.lastSnapshot))).font(.subheadline.bold().monospacedDigit()).foregroundStyle(metric.value(from: store.lastSnapshot) == nil ? .secondary : .primary) }.padding(.vertical, 4)
        }
    }
}

private struct TrendsView: View {
    @EnvironmentObject private var store: OncoSenseStore
    private let metrics: [SignalMetric] = [.restingHeartRate, .hrv, .respiratoryRate, .sleep, .exercise, .steps, .temperature, .weight]
    var body: some View {
        NavigationStack { ScrollView { LazyVStack(alignment: .leading, spacing: 14) { VStack(alignment: .leading, spacing: 6) { Text("Your history, not a population average").font(.title2.bold()); Text("Tap any trend for a deeper look at your own observations.").font(.footnote).foregroundStyle(.secondary) }; ForEach(metrics) { metric in NavigationLink { SignalInsightView(metric: metric) } label: { TrendCard(metric: metric, snapshots: store.snapshots) }.buttonStyle(.plain) }; Text("Persistent or concerning changes should be discussed with a qualified healthcare professional. OncoSense is not a diagnostic test.").font(.footnote).foregroundStyle(.secondary).padding(.top, 4) }.padding() }.navigationTitle("Trends").refreshable { await store.refresh() } }
    }
}

private struct TrendCard: View {
    let metric: SignalMetric
    let snapshots: [HealthSnapshot]
    private var values: [Double] { snapshots.sorted { $0.timestamp < $1.timestamp }.suffix(60).compactMap { metric.value(from: $0) } }
    var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Label(metric.title, systemImage: metric.icon).font(.headline); Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary) }; HStack(alignment: .bottom) { Text(metric.formatted(values.last)).font(.title3.bold().monospacedDigit()); if let c = metric.percentChange(values) { Text(String(format: "%+.0f%%", c)).font(.caption.bold().monospacedDigit()).foregroundStyle(.tint) }; Spacer(); Text("\(values.count) points").font(.caption).foregroundStyle(.secondary) }; Sparkline(values: values).frame(height: 54); Text(metric.shortDescription).font(.caption).foregroundStyle(.secondary) }.padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.primary.opacity(0.06))) }
}

private struct SignalInsightView: View {
    @EnvironmentObject private var store: OncoSenseStore
    let metric: SignalMetric
    private var values: [Double] { store.snapshots.sorted { $0.timestamp < $1.timestamp }.suffix(90).compactMap { metric.value(from: $0) } }
    private var baseline: Double? { values.isEmpty ? nil : values.reduce(0, +) / Double(values.count) }
    private var latest: Double? { values.last }
    private var change: Double? { metric.percentChange(values) }
    var body: some View { ScrollView { LazyVStack(alignment: .leading, spacing: 16) { header; chart; insight; grid; guidance }.padding() }.navigationTitle(metric.title).navigationBarTitleDisplayMode(.inline) }
    private var header: some View { VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: metric.icon).font(.system(size: 28, weight: .semibold)).foregroundStyle(.tint); VStack(alignment: .leading) { Text(metric.title).font(.title2.bold()); Text(metric.unitLabel).font(.subheadline).foregroundStyle(.secondary) } }; Text(metric.longDescription).font(.subheadline).foregroundStyle(.secondary) } }
    private var chart: some View { VStack(alignment: .leading, spacing: 10) { Text("YOUR RECENT HISTORY").font(.caption.bold()).foregroundStyle(.secondary); Sparkline(values: values).frame(height: 130); HStack { Text("Older"); Spacer(); Text("Latest") }.font(.caption).foregroundStyle(.secondary) }.padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous)) }
    private var insight: some View { VStack(alignment: .leading, spacing: 9) { Label(insightTitle, systemImage: insightIcon).font(.headline); Text(insightText).font(.subheadline); Text("This is a description of recorded data, not a medical diagnosis.").font(.caption).foregroundStyle(.secondary) }.padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous)) }
    private var grid: some View { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { InsightTile(title: "Latest", value: metric.formatted(latest), icon: "scope"); InsightTile(title: "Your average", value: metric.formatted(baseline), icon: "minus"); InsightTile(title: "Change", value: change.map { String(format: "%+.1f%%", $0) } ?? "Not enough data", icon: "arrow.up.right"); InsightTile(title: "Observations", value: "\(values.count)", icon: "chart.bar") } }
    private var guidance: some View { VStack(alignment: .leading, spacing: 8) { Text("How to read this").font(.headline); Text(metric.insightGuidance).font(.subheadline).foregroundStyle(.secondary); Text("If a change is persistent, unexpected, or concerning, bring the trend and your Care notes to a qualified healthcare professional.").font(.footnote).foregroundStyle(.secondary) } }
    private var insightTitle: String { guard let l = latest, let b = baseline else { return "Collecting your baseline" }; return abs(l - b) < metric.meaningfulDifference(for: b) ? "Close to your personal average" : l > b ? "Above your recent average" : "Below your recent average" }
    private var insightIcon: String { guard let l = latest, let b = baseline else { return "hourglass" }; return l >= b ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill" }
    private var insightText: String { guard let l = latest, let b = baseline else { return "OncoSense needs more real observations before it can describe a personal pattern. Missing data is never filled with guesses." }; let d = l - b; if abs(d) < metric.meaningfulDifference(for: b) { return "Your latest recorded value is \(metric.formatted(l)), close to your average of \(metric.formatted(b))." }; return "Your latest recorded value is \(metric.formatted(l)), about \(metric.formatted(abs(d))) \(d > 0 ? "above" : "below") your personal average. Look at the full history and context rather than one point." }
}

private struct InsightTile: View { let title: String; let value: String; let icon: String; var body: some View { VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(.tint); Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.subheadline.bold().monospacedDigit()).lineLimit(2) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous)) } }

private struct Sparkline: View {
    let values: [Double]
    var body: some View { GeometryReader { geo in if values.count > 1 { let minV = values.min() ?? 0; let maxV = values.max() ?? 1; let range = max(maxV - minV, 0.0001); Path { p in for i in values.indices { let x = geo.size.width * CGFloat(i) / CGFloat(values.count - 1); let y = geo.size.height - ((CGFloat(values[i] - minV) / CGFloat(range)) * geo.size.height); if i == values.startIndex { p.move(to: .init(x: x, y: y)) } else { p.addLine(to: .init(x: x, y: y)) } } }.stroke(.tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)) } else { ContentUnavailableView("Not enough data", systemImage: "chart.xyaxis.line", description: Text("Keep collecting real HealthKit observations.")) } } }
}

private enum SignalMetric: String, CaseIterable, Identifiable, Equatable {
    case restingHeartRate, heartRate, hrv, respiratoryRate, temperature, sleep, exercise, steps, activeEnergy, weight
    var id: String { rawValue }
    var title: String { switch self { case .restingHeartRate: return "Resting heart rate"; case .heartRate: return "Heart rate"; case .hrv: return "Heart-rate variability"; case .respiratoryRate: return "Respiratory rate"; case .temperature: return "Sleeping wrist temperature"; case .sleep: return "Sleep"; case .exercise: return "Exercise"; case .steps: return "Steps"; case .activeEnergy: return "Active energy"; case .weight: return "Weight" } }
    var icon: String { switch self { case .restingHeartRate, .heartRate: return "heart.fill"; case .hrv: return "waveform.path.ecg.rectangle"; case .respiratoryRate: return "lungs.fill"; case .temperature: return "thermometer.medium"; case .sleep: return "moon.fill"; case .exercise: return "figure.run"; case .steps: return "figure.walk"; case .activeEnergy: return "flame.fill"; case .weight: return "scalemass.fill" } }
    var unitLabel: String { switch self { case .restingHeartRate, .heartRate: return "beats per minute"; case .hrv: return "milliseconds"; case .respiratoryRate: return "breaths per minute"; case .temperature: return "degrees Celsius"; case .sleep: return "hours"; case .exercise: return "minutes"; case .steps: return "steps"; case .activeEnergy: return "kilocalories"; case .weight: return "kilograms" } }
    var shortDescription: String { switch self { case .restingHeartRate: return "Your resting heart-rate reading"; case .heartRate: return "Latest heart-rate reading"; case .hrv: return "SDNN from Apple Health"; case .respiratoryRate: return "Latest breathing rate"; case .temperature: return "Wrist temperature when available"; case .sleep: return "Sleep in the latest 24-hour window"; case .exercise: return "Apple Exercise time"; case .steps: return "Steps in the latest 24-hour window"; case .activeEnergy: return "Active energy in the latest 24-hour window"; case .weight: return "Latest body-mass reading" } }
    var longDescription: String { shortDescription + ". OncoSense compares this measurement with your own recorded history rather than a diagnostic threshold." }
    var insightGuidance: String { switch self { case .restingHeartRate: return "Resting heart rate can vary with activity, recovery, stress, illness, medication and measurement conditions."; case .heartRate: return "Heart rate naturally changes with activity and context. Repeated observations are more useful than one reading."; case .hrv: return "HRV is sensitive to sleep, stress, recovery and measurement conditions. Focus on your own pattern."; case .respiratoryRate: return "Breathing rate can vary with sleep, activity and illness. Use the longitudinal pattern as context."; case .temperature: return "Wrist temperature is not the same as a clinical body-temperature measurement and can vary with environment and wear conditions."; case .sleep: return "Sleep duration is one part of recovery and can vary from night to night."; case .exercise: return "Exercise time reflects recorded activity and can change with routine, recovery and device use."; case .steps: return "Step counts reflect recorded movement and are useful as an activity context signal."; case .activeEnergy: return "Active energy is an estimate from Apple Health and is best interpreted over repeated observations."; case .weight: return "Body mass can fluctuate for many reasons. Look for sustained patterns rather than one measurement." } }
    func value(from s: HealthSnapshot?) -> Double? { guard let s else { return nil }; switch self { case .restingHeartRate: return s.restingHeartRate; case .heartRate: return s.heartRate; case .hrv: return s.hrv; case .respiratoryRate: return s.respiratoryRate; case .temperature: return s.temperature; case .sleep: return s.sleepHours; case .exercise: return s.activityMinutes; case .steps: return s.steps; case .activeEnergy: return s.activeEnergy; case .weight: return s.weightKg } }
    func formatted(_ v: Double?) -> String { guard let v else { return "No data" }; switch self { case .restingHeartRate, .heartRate: return "\(Int(v.rounded())) bpm"; case .hrv: return "\(Int(v.rounded())) ms"; case .respiratoryRate: return String(format: "%.1f /min", v); case .temperature: return String(format: "%.2f °C", v); case .sleep: return String(format: "%.1f h", v); case .exercise: return "\(Int(v.rounded())) min"; case .steps: return "\(Int(v.rounded()))"; case .activeEnergy: return "\(Int(v.rounded())) kcal"; case .weight: return String(format: "%.1f kg", v) } }
    func percentChange(_ values: [Double]) -> Double? { guard values.count >= 2, let f = values.first, let l = values.last, f != 0 else { return nil }; return ((l - f) / abs(f)) * 100 }
    func meaningfulDifference(for baseline: Double) -> Double { max(abs(baseline) * 0.05, self == .temperature ? 0.05 : 0.5) }
}

private struct ActionRow: View { let icon: String; let title: String; let detail: String; let action: () -> Void; var body: some View { Button(action: action) { HStack(spacing: 12) { Image(systemName: icon).frame(width: 34, height: 34).background(.tint.opacity(0.12), in: Circle()).foregroundStyle(.tint); VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary) }.contentShape(Rectangle()) }.buttonStyle(.plain) } }
private extension View { func cardStyle() -> some View { padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.primary.opacity(0.05))) } }

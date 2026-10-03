import SwiftUI

@main
struct OncoSenseApp: App {
    @StateObject private var store = OncoSenseStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
                .tint(.oncoAccent)
                .preferredColorScheme(nil)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "heart.text.square.fill") }
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "chart.xyaxis.line") }
            InsightView()
                .tabItem { Label("Insights", systemImage: "sparkles") }
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Good morning")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("ONCOSENSE")
                                .font(.title.bold())
                        }
                        Spacer()
                        Image(systemName: "applewatch")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.oncoAccent)
                    }

                    OncoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EARLY SCREENING")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline) {
                                Text(store.result.state.title)
                                    .font(.system(size: 44, weight: .black, design: .rounded))
                                    .foregroundStyle(.oncoAccent)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("SIGNAL")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                    Text("\(store.result.signal)/100")
                                        .font(.headline.monospacedDigit())
                                }
                            }
                            Text(store.result.summary)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR SIGNALS")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            SignalPill(title: "Heart", value: "Stable", color: .oncoAccent)
                            SignalPill(title: "Breathing", value: "Stable", color: .oncoAccent)
                        }
                        HStack(spacing: 10) {
                            SignalPill(title: "Sleep", value: "Good", color: .oncoAccent)
                            SignalPill(title: "Activity", value: "Normal", color: .oncoAccent)
                        }
                    }

                    HStack(spacing: 10) {
                        SignalPill(title: "Persistence", value: "\(store.result.persistenceDays)d", color: .primary)
                        SignalPill(title: "Data quality", value: "\(store.result.dataQuality)%", color: .oncoAccent)
                    }

                    Button {
                        store.runDemoAnalysis()
                    } label: {
                        Label("Run analysis", systemImage: "waveform.path.ecg")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .background(Color.oncoBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TimelineView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    Label(store.result.summary, systemImage: "circle.fill")
                    Text("Signal \(store.result.signal)/100 · Data quality \(store.result.dataQuality)%")
                        .foregroundStyle(.secondary)
                }
                Section("Recent snapshots") {
                    ForEach(store.snapshots.prefix(20)) { snapshot in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(snapshot.timestamp, style: .date)
                            Text(snapshot.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.oncoBackground)
            .navigationTitle("Timeline")
        }
    }
}

private struct InsightView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this signal?")
                        .font(.largeTitle.bold())
                    Text("OncoSense compares your recent physiological pattern with your personal baseline and looks for persistent multi-signal changes.")
                        .foregroundStyle(.secondary)

                    OncoCard {
                        VStack(spacing: 0) {
                            InsightRow(title: "Signal", value: "\(store.result.signal)/100")
                            Divider().padding(.vertical, 8)
                            InsightRow(title: "Persistence", value: "\(store.result.persistenceDays) days")
                            Divider().padding(.vertical, 8)
                            InsightRow(title: "Data quality", value: "\(store.result.dataQuality)%")
                        }
                    }

                    Text("OncoSense is a research screening system. A signal is not a diagnosis and should be interpreted with appropriate clinical context.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color.oncoBackground)
            .navigationTitle("Insights")
        }
    }
}

private struct InsightRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

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
                .tabItem { Label("Home", systemImage: "heart.text.square.fill") }
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "chart.xyaxis.line") }
            InsightView()
                .tabItem { Label("Why", systemImage: "sparkles") }
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Good morning")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("ONCOSENSE")
                                .font(.title.bold())
                        }
                        Spacer()
                        Image(systemName: "applewatch")
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("EARLY SCREENING")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline) {
                            Text(store.result.state.title)
                                .font(.system(size: 44, weight: .black))
                            Spacer()
                            Text("\(store.result.signal)/100")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Text(store.result.summary)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR SIGNALS").font(.caption.bold()).foregroundStyle(.secondary)
                        ForEach(Array(store.result.contributors.enumerated()), id: \.offset) { _, item in
                            Label(item, systemImage: icon(for: item))
                        }
                    }

                    HStack(spacing: 12) {
                        MetricCard(title: "Persistence", value: "\(store.result.persistenceDays)d")
                        MetricCard(title: "Data quality", value: "\(store.result.dataQuality)%")
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func icon(for item: String) -> String {
        if item.contains("Heart") { return "heart.fill" }
        if item.contains("Breathing") { return "lungs.fill" }
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
                Section("Today") {
                    Label(store.result.summary, systemImage: "circle.fill")
                    Text("Signal \(store.result.signal)/100 · Data quality \(store.result.dataQuality)%")
                        .foregroundStyle(.secondary)
                }
                Section("Recent snapshots") {
                    ForEach(store.snapshots.prefix(20)) { snapshot in
                        VStack(alignment: .leading) {
                            Text(snapshot.timestamp, style: .date)
                            Text(snapshot.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
        }
    }
}

private struct InsightView: View {
    @EnvironmentObject private var store: OncoSenseStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Why this signal?")
                        .font(.largeTitle.bold())
                    Text("OncoSense compares your recent physiological pattern with your personal baseline and looks for persistent multi-signal changes.")
                        .foregroundStyle(.secondary)
                    InsightRow(title: "Signal", value: "\(store.result.signal)/100")
                    InsightRow(title: "Persistence", value: "\(store.result.persistenceDays) days")
                    InsightRow(title: "Data quality", value: "\(store.result.dataQuality)%")
                    Text("The screening signal is a research feature. It is not a diagnosis or a substitute for clinical evaluation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct InsightRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack { Text(title); Spacer(); Text(value).bold() }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

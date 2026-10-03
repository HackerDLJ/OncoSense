import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var screening = false
    @State private var result = ScreeningResult.demo
    @State private var healthReady = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack {
                    Text("🧬 ONCOSENSE").font(.headline.bold())
                    Spacer()
                    Circle().fill(screening ? Color.green : Color.secondary).frame(width: 7, height: 7)
                }

                WatchGlass {
                    VStack(spacing: 4) {
                        Text("EARLY SCREENING").font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(result.state.title)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(result.state == .low ? .green : .orange)
                        Text(result.summary)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 7) {
                    WatchGlass { SmallStat(title: "SIGNAL", value: "\(result.signal)") }
                    WatchGlass { SmallStat(title: "QUALITY", value: "\(result.dataQuality)%") }
                }

                WatchGlass {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SIGNALS").font(.caption2.bold()).foregroundStyle(.secondary)
                        ForEach(Array(result.contributors.prefix(4).enumerated()), id: \.offset) { _, signal in
                            SignalRow(text: signal)
                        }
                    }
                }

                if !healthReady {
                    Button("Connect Apple Health") {
                        health.requestAuthorization { authorization in
                            if case .success = authorization { healthReady = true }
                        }
                    }
                    .buttonStyle(WatchGlassButtonStyle())
                } else {
                    Label("Apple Health connected", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

                Button(screening ? "Screening On" : "Start Screening") {
                    screening = true
                }
                .buttonStyle(WatchGlassButtonStyle())

                Text("Updated just now · View details on iPhone")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 7)
        }
    }
}

private struct SignalRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(text).font(.caption2)
            Spacer()
        }
    }
}

private struct SmallStat: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 1) {
            Text(title).font(.system(size: 8)).foregroundStyle(.secondary)
            Text(value).font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

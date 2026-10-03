import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var screening = false
    @State private var result = ScreeningResult.demo
    @State private var healthReady = false

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                Text("🧬 ONCOSENSE")
                    .font(.headline.bold())

                Text(screening ? "● EARLY SCREENING" : "○ READY")
                    .font(.caption2)
                    .foregroundStyle(screening ? .green : .secondary)

                Text("CANCER RISK SIGNAL")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(result.state.title)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(result.state == .low ? .green : .orange)

                Text(result.summary)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Divider()

                ForEach(Array(result.contributors.prefix(4).enumerated()), id: \.offset) { _, signal in
                    SignalRow(text: signal)
                }

                Divider()

                HStack(spacing: 12) {
                    SmallStat(title: "SIGNAL", value: "\(result.signal)")
                    SmallStat(title: "QUALITY", value: "\(result.dataQuality)%")
                }

                if !healthReady {
                    Button("Connect Apple Health") {
                        health.requestAuthorization { authorization in
                            if case .success = authorization { healthReady = true }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Label("Apple Health connected", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

                Button(screening ? "Screening On" : "Start Screening") {
                    screening = true
                }
                .buttonStyle(.bordered)

                Text("Updated just now · View details on iPhone")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct SignalRow: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.caption2)
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

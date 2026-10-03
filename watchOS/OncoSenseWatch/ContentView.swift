import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var screening = false
    @State private var state = "LOW"
    @State private var message = "Your recent physiological pattern is stable."
    @State private var healthReady = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("🧬 ONCOSENSE")
                    .font(.headline.bold())

                Text(screening ? "● EARLY SCREENING" : "○ READY")
                    .font(.caption2)
                    .foregroundStyle(screening ? .green : .secondary)

                Text("CANCER RISK SIGNAL")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(state)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(state == "LOW" ? .green : .orange)

                Text(message)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Divider()

                SignalRow(icon: "♥", title: "Heart pattern", value: "Stable")
                SignalRow(icon: "🫁", title: "Breathing", value: "Stable")
                SignalRow(icon: "🌡", title: "Temperature", value: "Stable")
                SignalRow(icon: "☾", title: "Sleep", value: "Stable")

                Divider()

                if !healthReady {
                    Button("Connect Apple Health") {
                        health.requestAuthorization { result in
                            if case .success = result { healthReady = true }
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
                    message = "OncoSense is watching for persistent changes from your personal baseline."
                }
                .buttonStyle(.bordered)

                Text("LAST 30 DAYS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                Text("No persistent cancer-related pattern detected")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct SignalRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(icon).frame(width: 18)
            Text(title).font(.caption2)
            Spacer()
            Text(value).font(.caption2).foregroundStyle(.green)
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    ContentView().environmentObject(HealthKitManager())
}

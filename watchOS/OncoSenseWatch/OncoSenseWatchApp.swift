import SwiftUI

@main
struct OncoSenseWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var monitoring = true

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("🧬 ONCOSENSE")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("EARLY SCREEN")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(spacing: 2) {
                    Text("SCREENING STATUS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("LOW SIGNAL")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 5)

                Text("Your health pattern is stable.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)

                Divider()

                SignalRow(title: "Heart", status: "Stable", symbol: "♥")
                SignalRow(title: "Breathing", status: "Stable", symbol: "♧")
                SignalRow(title: "Temperature", status: "Stable", symbol: "🌡")
                SignalRow(title: "Sleep", status: "Stable", symbol: "☾")
                SignalRow(title: "Activity", status: "Stable", symbol: "●")

                Divider()

                Text("No persistent cancer-related pattern detected.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(monitoring ? "Pause Screening" : "Start Screening") {
                    monitoring.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 8)
        }
    }
}

struct SignalRow: View {
    let title: String
    let status: String
    let symbol: String

    var body: some View {
        HStack {
            Text(symbol)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}

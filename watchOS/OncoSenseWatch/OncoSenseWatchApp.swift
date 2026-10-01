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
                Text("ONCOSENSE")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(monitoring ? "● MONITORING" : "○ PAUSED")
                    .font(.caption2)
                    .foregroundStyle(monitoring ? .green : .secondary)

                VStack(spacing: 2) {
                    Text("BODY STATUS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("NORMAL")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 5)

                Divider()

                MetricRow(title: "Heart rate", value: "Normal", icon: "♥")
                MetricRow(title: "Breathing", value: "Normal", icon: "♧")
                MetricRow(title: "Sleep", value: "Good", icon: "☾")
                MetricRow(title: "Activity", value: "Normal", icon: "●")

                Divider()

                Text("No persistent changes detected.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(monitoring ? "Pause" : "Start") {
                    monitoring.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 8)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Text(icon)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            Spacer()
        }
    }
}

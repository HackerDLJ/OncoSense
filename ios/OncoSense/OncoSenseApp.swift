import SwiftUI

@main
struct OncoSenseApp: App {
    var body: some Scene {
        WindowGroup {
            iOSDashboardView()
        }
    }
}

struct iOSDashboardView: View {
    @State private var state = "LOW"
    @State private var score = 0.0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ONCOSENSE")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text(state)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(state == "LOW" ? .green : .orange)
                        Text("Personalized early-screening signal")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                }
                Section("Today's signals") {
                    Label("Heart pattern · Stable", systemImage: "heart.fill")
                    Label("Breathing · Stable", systemImage: "lungs.fill")
                    Label("Sleep · Stable", systemImage: "moon.fill")
                    Label("Activity · Stable", systemImage: "figure.walk")
                }
                Section("Signal score") {
                    Text(String(format: "%.0f / 100", score))
                    Text("This is a research signal based on longitudinal physiological change, not a cancer diagnosis.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("OncoSense")
        }
    }
}

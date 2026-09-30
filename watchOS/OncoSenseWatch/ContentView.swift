import SwiftUI

struct ContentView: View {
    @State private var monitoring = false
    @State private var status = "Building your personal baseline"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: monitoring ? "waveform.path.ecg" : "heart.text.square")
                    .font(.system(size: 42))
                    .foregroundStyle(.green)

                Text("OncoSense")
                    .font(.headline)

                Text(monitoring ? "Monitoring" : "Ready")
                    .font(.title3.bold())

                Text(status)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(monitoring ? "Monitoring On" : "Start Baseline") {
                    monitoring = true
                    status = "Collecting longitudinal health patterns. This is not a cancer diagnosis."
                }
                .buttonStyle(.borderedProminent)

                Text("OncoSense looks for persistent changes from your own baseline. It does not diagnose cancer.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

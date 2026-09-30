import SwiftUI

struct AnomalyView: View {
    let score: Double
    let level: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Change Signature")
                .font(.headline)
            Text("\(Int(score))")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text(level.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.footnote)
            Text("This is a physiological anomaly signal, not a cancer diagnosis.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    AnomalyView(score: 46, level: "watch")
}

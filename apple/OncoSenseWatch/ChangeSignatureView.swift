import SwiftUI

struct ChangeSignatureView: View {
    let signature: ChangeSignature

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Change Signature")
                    .font(.headline)
                Text(signature.status == .persistentChange ? "Persistent change detected" : "No persistent change detected")
                    .font(.title3.bold())
                Text("Window: \(signature.windowDays) days")
                    .foregroundStyle(.secondary)
                ProgressView(value: min(max(signature.anomalyScore, 0), 1))
                ForEach(signature.contributors) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.metric).font(.subheadline.bold())
                        Text(String(format: "%+.1f%% from personal baseline", item.percentChange))
                            .font(.caption)
                        Text(String(format: "z-score %.2f", item.zScore))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
                Text("Research signal only. This screen does not diagnose cancer or any disease.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
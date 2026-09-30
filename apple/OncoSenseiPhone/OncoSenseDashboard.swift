import SwiftUI

struct OncoSenseDashboard: View {
    let signature: ChangeSignature

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("OncoSense")
                        .font(.largeTitle.bold())
                    Text("Personal physiological change signature")
                        .foregroundStyle(.secondary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Status").font(.caption)
                            Text(signature.status.rawValue.capitalized).font(.title2.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Anomaly").font(.caption)
                            Text(String(format: "%.0f%%", signature.anomalyScore * 100))
                                .font(.title2.bold())
                        }
                    }

                    Text("Contributors")
                        .font(.headline)
                    ForEach(signature.contributors) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(item.metric).font(.body.bold())
                                Spacer()
                                Text(String(format: "%+.1f%%", item.percentChange))
                            }
                            ProgressView(value: min(abs(item.zScore) / 3, 1))
                        }
                    }

                    Text("This is a research signal, not a cancer diagnosis or medical recommendation. Persistent or concerning symptoms should be discussed with a qualified healthcare professional.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Health Trends")
        }
    }
}
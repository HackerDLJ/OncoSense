import SwiftUI

// Existing supporting views are defined above in this file.
// The Apple Watch connection view below intentionally separates pairing,
// app installation, background sync, and live reachability.

struct WatchConnectionView: View {
    @EnvironmentObject private var store: OncoSenseStore
    @Environment(\.dismiss) private var dismiss

    private var statusTitle: String {
        if !store.sync.isPaired { return "Apple Watch not paired with iPhone" }
        if !store.sync.counterpartInstalled { return "OncoSense Watch app not installed" }
        if !store.sync.isActivated { return "Starting Apple Watch sync" }
        if store.sync.isReachable { return "Apple Watch connected" }
        return "Apple Watch paired · background sync ready"
    }

    private var statusDetail: String {
        if !store.sync.isPaired {
            return "Pair the Apple Watch with this iPhone first. This is a device pairing state, not an OncoSense app error."
        }
        if !store.sync.counterpartInstalled {
            return "The iPhone can see the paired Watch, but OncoSense is not installed on the active Watch yet. Run the OncoSenseWatch target on the physical Watch once."
        }
        if !store.sync.isActivated {
            return store.sync.activationError ?? "WatchConnectivity is activating. Keep the iPhone and Watch nearby and leave both apps installed."
        }
        if store.sync.isReachable {
            return "The Watch app is available for live communication. Background transfers remain available when the live channel closes."
        }
        return "The Watch is paired and installed. Live reachability is optional, so this is not treated as a pairing failure."
    }

    private var statusIcon: String {
        if !store.sync.isPaired { return "applewatch.slash" }
        if !store.sync.counterpartInstalled { return "applewatch.and.arrow.forward" }
        if store.sync.isReachable { return "applewatch.radiowaves.left.and.right" }
        return "applewatch"
    }

    private var statusSymbolColor: Color {
        if !store.sync.isPaired || !store.sync.counterpartInstalled { return .orange }
        if store.sync.isReachable { return .green }
        return .blue
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 9) {
                        Label {
                            Text(statusTitle)
                        } icon: {
                            Image(systemName: statusIcon)
                                .foregroundStyle(statusSymbolColor)
                        }
                        .font(.headline)

                        Text(statusDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Pairing diagnostics") {
                    diagnosticRow(
                        "Apple Watch paired",
                        store.sync.isPaired,
                        store.sync.isPaired ? "Device relationship detected" : "Pair the Watch in the iPhone Watch app first"
                    )
                    diagnosticRow(
                        "OncoSense Watch app",
                        store.sync.counterpartInstalled,
                        store.sync.counterpartInstalled ? "Installed on the active Watch" : "Run OncoSenseWatch on the physical Watch"
                    )
                    diagnosticRow(
                        "WatchConnectivity session",
                        store.sync.isActivated,
                        store.sync.isActivated ? "Activated" : "Waiting for activation"
                    )
                    diagnosticRow(
                        "Live channel",
                        store.sync.isReachable,
                        store.sync.isReachable ? "Available now" : "Not currently live · background sync can still work"
                    )
                }

                Section("Sync status") {
                    LabeledContent("Pending transfers", value: "\(store.sync.pendingTransfers)")
                    LabeledContent("Last sent", value: store.sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Not yet")
                    LabeledContent("Last received", value: store.sync.lastReceived.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Not yet")
                }

                Section {
                    Button("Sync latest health snapshot") {
                        store.syncLatestToWatch()
                    }
                    .disabled(!store.sync.isActivated || !store.sync.counterpartInstalled)

                    Button("Refresh from Apple Health") {
                        Task { await store.refresh() }
                    }
                }

                Section("Physical-device setup") {
                    Text("For final verification, use a physical paired iPhone + Apple Watch. In Xcode, install the iPhone app and then run the OncoSenseWatch scheme on the physical Watch. Once the Watch app is installed, this screen should move from 'not installed' to 'background sync ready'.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About live connection") {
                    Text("Apple's isReachable flag means the counterpart app is available for live messaging right now. A false value does not mean the devices are unpaired. OncoSense uses durable application context and queued user-info transfers for health synchronization instead of treating live reachability as the transport itself.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Apple Watch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func diagnosticRow(_ title: String, _ passed: Bool, _ detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: passed ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(passed ? .green : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 3)
    }
}

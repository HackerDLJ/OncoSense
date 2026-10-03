import Foundation
import Combine
import WatchConnectivity

/// One connectivity path for iPhone <-> Apple Watch.
///
/// Health snapshots are state, not live chat. We therefore use
/// `updateApplicationContext` as the primary transport. It works while the
/// counterpart is not reachable and always represents the newest snapshot.
/// `sendMessage` is intentionally not used for health sync because it requires
/// the counterpart app to be reachable and was the source of the timeout spam.
final class OncoSenseConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = OncoSenseConnectivity()

    @Published private(set) var isReachable = false
    @Published private(set) var isActivated = false
    @Published private(set) var counterpartInstalled = false
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastReceived: Date?
    @Published private(set) var pendingTransfers = 0

    var onSnapshot: ((HealthSnapshot) -> Void)?
    #if os(watchOS)
    var onSnapshotRequest: (() -> Void)?
    #endif

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var pendingSnapshot: HealthSnapshot?

    private override init() {
        super.init()
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
        publishState(session)
    }

    func send(snapshot: HealthSnapshot) {
        pendingSnapshot = snapshot
        guard let session,
              session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        do {
            // Durable latest-state sync. This is delivered when the counterpart
            // gets an opportunity, even when `isReachable == false`.
            try session.updateApplicationContext(["kind": "healthSnapshot", "snapshot": data])
            DispatchQueue.main.async {
                self.lastSync = .now
            }
        } catch {
            print("[OncoSenseConnectivity] application context update failed: \(error.localizedDescription)")
        }
        publishState(session)
    }

    /// Ask the Watch for its latest HealthKit snapshot.
    /// This is a background request, so it does not depend on live reachability.
    func requestSnapshotFromWatch() {
        guard let session,
              session.activationState == .activated else { return }

        // UserInfo is appropriate for a command that should eventually arrive.
        // Unlike sendMessage, it does not require the Watch app to be live.
        session.transferUserInfo(["kind": "command", "command": "requestSnapshot"])
        publishState(session)
    }

    private func receiveSnapshot(_ userInfo: [String: Any], session: WCSession) {
        guard let data = userInfo["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(HealthSnapshot.self, from: data) else { return }

        DispatchQueue.main.async {
            self.lastReceived = .now
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
            self.onSnapshot?(snapshot)
        }
    }

    private func handle(_ payload: [String: Any], session: WCSession) {
        if let command = payload["command"] as? String {
            #if os(watchOS)
            if command == "requestSnapshot" {
                DispatchQueue.main.async {
                    self.onSnapshotRequest?()
                }
            }
            #endif
        }

        if payload["snapshot"] != nil {
            receiveSnapshot(payload, session: session)
        }

        publishState(session)
    }

    private func publishState(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivated = session.activationState == .activated
            self.isReachable = session.isReachable
            #if os(iOS)
            self.counterpartInstalled = session.isWatchAppInstalled
            #else
            self.counterpartInstalled = session.isCompanionAppInstalled
            #endif
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[OncoSenseConnectivity] activation failed: \(error.localizedDescription)")
        }
        publishState(session)

        // If the app loaded a snapshot before WatchConnectivity finished
        // activating, send it now instead of silently dropping the first sync.
        if activationState == .activated, let pendingSnapshot {
            send(snapshot: pendingSnapshot)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        publishState(session)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(applicationContext, session: session)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo, session: session)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Keep compatibility with an older installed build, but all new health
        // sync uses applicationContext/userInfo and never depends on this path.
        handle(message, session: session)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        publishState(session)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}

import Foundation
import Combine
import WatchConnectivity

/// Reliable iPhone <-> Apple Watch transport for OncoSense.
///
/// Health snapshots are state, not live chat. The latest snapshot uses
/// `updateApplicationContext`, while explicit Watch requests use
/// `transferUserInfo`. Neither path requires the counterpart app to be in the
/// foreground. `sendMessage` is intentionally not used for health sync.
final class OncoSenseConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = OncoSenseConnectivity()

    @Published private(set) var isReachable = false
    @Published private(set) var isActivated = false
    @Published private(set) var counterpartInstalled = false
    @Published private(set) var isPaired = false
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastReceived: Date?
    @Published private(set) var pendingTransfers = 0
    @Published private(set) var activationError: String?

    var onSnapshot: ((HealthSnapshot) -> Void)?
    #if os(watchOS)
    var onSnapshotRequest: (() -> Void)?
    #endif

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var pendingSnapshot: HealthSnapshot?
    private var hasRequestedActivation = false

    private override init() {
        super.init()
    }

    func activate() {
        guard let session else { return }
        session.delegate = self

        if session.activationState != .activated && !hasRequestedActivation {
            hasRequestedActivation = true
            DispatchQueue.main.async {
                self.activationError = nil
            }
            session.activate()
        }

        publishState(session)
    }

    func send(snapshot: HealthSnapshot) {
        pendingSnapshot = snapshot
        guard let session,
              session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else {
            publishState(session)
            return
        }

        do {
            // Latest-state transport. The system can deliver this later when
            // the counterpart becomes available.
            try session.updateApplicationContext([
                "kind": "healthSnapshot",
                "snapshot": data
            ])
            DispatchQueue.main.async {
                self.lastSync = .now
            }
        } catch {
            print("[OncoSenseConnectivity] application context update failed: \(error.localizedDescription)")
        }
        publishState(session)
    }

    /// Ask the Watch for its latest HealthKit snapshot.
    /// This is a queued request and does not depend on live reachability.
    func requestSnapshotFromWatch() {
        guard let session,
              session.activationState == .activated,
              counterpartIsInstalled(on: session) else {
            publishState(session)
            return
        }

        session.transferUserInfo([
            "kind": "command",
            "command": "requestSnapshot"
        ])
        publishState(session)
    }

    private func counterpartIsInstalled(on session: WCSession) -> Bool {
        guard session.activationState == .activated else { return false }
        #if os(iOS)
        return session.isWatchAppInstalled
        #else
        return session.isCompanionAppInstalled
        #endif
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

    private func publishState(_ session: WCSession?) {
        guard let session else { return }

        let active = session.activationState == .activated
        let paired: Bool
        let installed: Bool

        #if os(iOS)
        // Apple documents these device-state properties as valid only after
        // the WCSession is activated. Do not read them during activation.
        paired = active ? session.isPaired : false
        installed = active ? session.isWatchAppInstalled : false
        #else
        paired = active
        installed = active ? session.isCompanionAppInstalled : false
        #endif

        let reachable = active && session.isReachable
        let transfers = active ? session.outstandingUserInfoTransfers.count : 0

        DispatchQueue.main.async {
            self.isActivated = active
            self.isReachable = reachable
            self.isPaired = paired
            self.counterpartInstalled = installed
            self.pendingTransfers = transfers
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.activationError = error?.localizedDescription
            self.isActivated = activationState == .activated
        }

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

    func sessionWatchStateDidChange(_ session: WCSession) {
        publishState(session)
    }

    #if os(iOS)
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        publishState(session)
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(applicationContext, session: session)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo, session: session)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Compatibility with an older installed build. New health sync never
        // depends on live messaging.
        handle(message, session: session)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        publishState(session)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        hasRequestedActivation = false
        session.activate()
    }
#endif
}

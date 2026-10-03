import Foundation
import Combine
import WatchConnectivity

final class OncoSenseConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = OncoSenseConnectivity()

    @Published private(set) var isReachable = false
    @Published private(set) var isActivated = false
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastReceived: Date?
    @Published private(set) var pendingTransfers = 0

    var onSnapshot: ((HealthSnapshot) -> Void)?
    #if os(watchOS)
    var onSnapshotRequest: (() -> Void)?
    #endif

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

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
        guard let session,
              session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else { return }

        let payload: [String: Any] = ["snapshot": data]

        // Application context represents the newest known state and survives
        // temporary reachability changes.
        try? session.updateApplicationContext(payload)

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                // The application context remains the durable latest-state path.
                print("[OncoSenseConnectivity] sendMessage failed: \(error.localizedDescription)")
            }
        } else {
            session.transferUserInfo(payload)
        }

        DispatchQueue.main.async {
            self.lastSync = .now
        }
        publishState(session)
    }

    /// Ask the Watch to read its current HealthKit snapshot and send it back.
    /// If the Watch is not reachable, queue the request for later delivery.
    func requestSnapshotFromWatch() {
        guard let session,
              session.activationState == .activated else { return }

        let request: [String: Any] = ["command": "requestSnapshot"]
        if session.isReachable {
            session.sendMessage(request, replyHandler: nil) { error in
                print("[OncoSenseConnectivity] snapshot request failed: \(error.localizedDescription)")
            }
        } else {
            session.transferUserInfo(request)
        }
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

    private func handle(_ userInfo: [String: Any], session: WCSession) {
        if let command = userInfo["command"] as? String {
            #if os(watchOS)
            if command == "requestSnapshot" {
                DispatchQueue.main.async {
                    self.onSnapshotRequest?()
                }
            }
            #endif
        }

        if userInfo["snapshot"] != nil {
            receiveSnapshot(userInfo, session: session)
        }

        publishState(session)
    }

    private func publishState(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivated = session.activationState == .activated
            self.isReachable = session.isReachable
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[OncoSenseConnectivity] activation failed: \(error.localizedDescription)")
        }
        publishState(session)
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

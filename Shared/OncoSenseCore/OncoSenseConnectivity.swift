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

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    func send(snapshot: HealthSnapshot) {
        guard let session, session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot) else { return }

        let payload: [String: Any] = ["snapshot": data]
        try? session.updateApplicationContext(payload)
        session.transferUserInfo(payload)
        publishState(session)
    }

    private func receive(_ userInfo: [String: Any], session: WCSession) {
        guard let data = userInfo["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(HealthSnapshot.self, from: data) else { return }
        DispatchQueue.main.async {
            self.lastSync = .now
            self.lastReceived = .now
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
            self.onSnapshot?(snapshot)
        }
    }

    private func publishState(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivated = session.activationState == .activated
            self.isReachable = session.isReachable
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
            if session.activationState == .activated {
                self.lastSync = .now
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isActivated = activationState == .activated
            self.isReachable = session.isReachable
            self.pendingTransfers = session.outstandingUserInfoTransfers.count
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        publishState(session)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        receive(applicationContext, session: session)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        receive(userInfo, session: session)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}

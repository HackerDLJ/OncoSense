import Foundation
import WatchConnectivity

final class WatchConnectivityBridge: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityBridge()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(snapshot: WearableSnapshot) {
        guard WCSession.default.isPaired || WCSession.default.isWatchAppInstalled else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            WCSession.default.transferUserInfo(["wearableSnapshot": data])
        } catch {
            print("OncoSense WatchConnectivity encode error: \(error)")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
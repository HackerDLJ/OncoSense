import Foundation
import Combine
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public struct WatchHealthPayload: Codable, Sendable {
    public let timestamp: Date
    public let heartRate: Double?
    public let hrv: Double?
    public let respiratoryRate: Double?
    public let temperature: Double?
    public let sleepDuration: Double?
    public let activity: Double?

    public init(timestamp: Date = .now, heartRate: Double? = nil, hrv: Double? = nil, respiratoryRate: Double? = nil, temperature: Double? = nil, sleepDuration: Double? = nil, activity: Double? = nil) {
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.hrv = hrv
        self.respiratoryRate = respiratoryRate
        self.temperature = temperature
        self.sleepDuration = sleepDuration
        self.activity = activity
    }
}

#if canImport(WatchConnectivity)
public final class WatchTransport: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = WatchTransport()
    @Published public private(set) var reachable = false
    @Published public private(set) var lastPayload: WatchHealthPayload?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    public func send(_ payload: WatchHealthPayload) {
        guard WCSession.isSupported() else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message: [String: Any] = ["type": "healthSnapshot", "payload": data]
        let session = WCSession.default
        if session.isReachable { session.sendMessage(message, replyHandler: nil) }
        session.transferUserInfo(message)
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.reachable = session.isReachable }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.reachable = session.isReachable }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { receive(message) }
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { receive(userInfo) }

    private func receive(_ message: [String: Any]) {
        guard let data = message["payload"] as? Data,
              let payload = try? JSONDecoder().decode(WatchHealthPayload.self, from: data) else { return }
        DispatchQueue.main.async { self.lastPayload = payload }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
#endif

import Foundation
import SwiftUI

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class WatchBridge: ObservableObject {
    @Published private(set) var lastSnapshot: WatchHealthPayload?
    @Published private(set) var connected = false

    #if canImport(WatchConnectivity)
    private let transport = WatchTransport.shared
    #endif

    init() {
        #if canImport(WatchConnectivity)
        transport.$lastPayload
            .receive(on: RunLoop.main)
            .assign(to: &$lastSnapshot)
        transport.$reachable
            .receive(on: RunLoop.main)
            .assign(to: &$connected)
        #endif
    }
}

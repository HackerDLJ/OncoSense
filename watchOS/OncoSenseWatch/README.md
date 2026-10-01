# OncoSense Apple Watch Demo

This folder contains a small SwiftUI watchOS demonstration screen designed to be understandable at a glance.

It intentionally does **not** claim to diagnose cancer. It demonstrates the future OncoSense interaction: a simple body-status summary, understandable health signals, and a persistent-change message.

## What the demo shows

- ONCOSENSE monitoring state
- Body status: NORMAL
- Heart rate: Normal
- Breathing: Normal
- Sleep: Good
- Activity: Normal
- Persistent-change message
- Start/Pause monitoring control

## Deploying to a physical Apple Watch

1. On a Mac, install a current Xcode version that supports your watchOS version.
2. Open Xcode and create a watchOS App project if this repository does not yet contain a generated `.xcodeproj`.
3. Add `OncoSenseWatchApp.swift` to the Watch App target.
4. Set the Watch App deployment target to a watchOS version supported by your device.
5. Sign in to Xcode with your Apple Account under Xcode Settings > Accounts.
6. Enable automatic signing for the Watch App target.
7. Pair the iPhone and Apple Watch, unlock both, and trust the Mac if prompted.
8. Select the physical Apple Watch as the run destination and press Run.

For the next production step, this demo should be connected to HealthKit and WatchConnectivity, replacing the demonstration status strings with real user-authorized data and the validated longitudinal analysis engine.

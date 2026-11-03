# OncoSense Apple Watch Research Layer

This directory contains the watchOS/iOS research architecture for OncoSense.

## Goal

OncoSense is **not** a cancer-diagnosis app. The wearable layer collects user-authorized longitudinal health signals, establishes a personal baseline, detects persistent multi-signal changes, and presents an explainable research signal for follow-up.

## Planned data flow

Apple Watch / HealthKit -> WatchConnectivity -> iPhone -> OncoSense API -> longitudinal feature engine -> anomaly model -> Change Signature

## Signals

Depending on device and HealthKit availability:
- heart rate
- HRV
- respiratory rate
- activity/exercise
- sleep
- sleeping wrist temperature
- blood oxygen where available
- ECG-derived data where permitted by Apple APIs

## Safety

A change signature is not a diagnosis, cancer probability, or medical advice. Models must be validated on appropriate datasets before any health claim is made.

## Xcode implementation

Create an iOS + watchOS app target in Xcode, enable only the HealthKit capabilities that are actually needed, request authorization at runtime, and use WatchConnectivity for app-to-watch synchronization. The Swift files in this directory are reference components and should be integrated into a signed Xcode project before deployment to a physical Apple Watch.
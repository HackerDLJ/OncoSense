# Changelog

## [2.0.0] - 2026-10-03

### Seamless Health Intelligence

OncoSense 2.0.0 is the major Apple ecosystem update, bringing the iPhone companion, watchOS experience, HealthKit foundation, longitudinal screening engine, WatchConnectivity architecture, ML research pipeline, adaptive UI, and CI-validated Apple builds together.

### Added

- iPhone companion dashboard with Home, Timeline, and Insights surfaces.
- watchOS screening experience with LOW, WATCH, and EARLY SIGNAL states.
- Shared `HealthSnapshot` and `ScreeningResult` models across iOS and watchOS.
- HealthKit authorization and wearable signal foundation.
- WatchConnectivity transport for Watch-to-iPhone health snapshots.
- Personal physiological baseline and longitudinal screening engine.
- Cancer ML research benchmark and wearable-model research pipeline.
- Adaptive Light Mode and Dark Mode design system.
- Liquid Glass-inspired surfaces with safe material fallback for older SDKs.
- XcodeGen project configuration for reproducible iOS/watchOS builds.
- CI validation for backend, iOS simulator, and watchOS simulator builds.

### Fixed

- iOS light/dark mode surface and contrast inconsistencies.
- watchOS Liquid Glass compilation issue on older Xcode SDKs.
- Missing generated `Info.plist` during Apple app validation.
- Inconsistent shared data contracts between Watch and iPhone.

### Research & Safety

OncoSense is a research screening system. Wearable physiological signals are not, by themselves, a validated cancer diagnosis. The cancer-specific wearable model requires appropriately sourced longitudinal wearable data, cancer outcomes, external validation, calibration, and clinical research before disease-related claims can be made.

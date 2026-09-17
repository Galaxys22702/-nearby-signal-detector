# Nearby Signal Detector

Version 0.4 development package for a native SwiftUI/CoreBluetooth iPhone app.

## Highlights

- Live Bluetooth Low Energy advertisement scanning and smoothed RSSI.
- Strongest-first device list with search and optional unnamed-device filtering.
- Session baseline with NEW-device marking and confirmed strong-signal alerts.
- Radar-style signal-strength visualisation and signal trend indicators.
- Live RSSI history and advertisement metadata inspection.
- Scanner preferences saved locally on the device.
- Xcode 26.6 iOS Simulator compile validation in GitHub Actions.
- Signed TestFlight release workflow prepared for Apple Developer/App Store Connect credentials.

The app intentionally treats RSSI as noisy received signal strength. It does not claim exact distance, direction, ownership, vehicle identity, or arbitrary RF detection.

See `NearbySignalDetector.swiftpm/README.md` for implementation details and `TESTFLIGHT_SETUP.md` for the Apple release path.

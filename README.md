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

## Build and installation

This repository contains a native iOS app. Build it with Xcode on macOS or use the macOS runners in GitHub Actions; Railway cannot run the SwiftUI app as a web service. Bluetooth scanning runs locally on the iPhone and does not require a server or an API key.

- **iOS compile check** validates a simulator build on pushes and pull requests.
- **Build unsigned iPhone IPA** produces a downloadable build artifact in the workflow run. It must be signed before it can be installed on an iPhone; it is not a TestFlight release.
- **Upload to TestFlight** creates and uploads a signed build after the Apple prerequisites and GitHub secrets in [TESTFLIGHT_SETUP.md](TESTFLIGHT_SETUP.md) are configured.

Use a physical iPhone to verify Bluetooth scanning; a successful simulator build does not test the Bluetooth radio.

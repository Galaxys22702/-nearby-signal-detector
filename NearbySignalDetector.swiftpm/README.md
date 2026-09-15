# Nearby Signal Detector v0.2

Native SwiftUI/CoreBluetooth prototype for iPhone and iPad.

## Current capabilities

- Foreground BLE advertisement scanning.
- Live RSSI and smoothed RSSI.
- Strongest-signal dashboard.
- Session baseline and NEW-device marking.
- Configurable in-app alert when a new device crosses an RSSI threshold.
- Automatic stale-device removal.
- Live RSSI history charts.
- Advertisement metadata inspection when iOS exposes it.

## Important limitation

This app cannot identify police or undercover vehicles, a device owner, or an exact physical location from BLE RSSI. It also cannot scan arbitrary RF frequencies with the iPhone radio hardware.

## Swift Playground

Open `NearbySignalDetector.swiftpm` in Swift Playground on iPad.

## Cloud compile check with XcodeGen

The repository also contains `project.yml`, which lets a macOS runner generate a normal Xcode project without committing a generated `.xcodeproj`.

On macOS:

```sh
brew install xcodegen
cd NearbySignalDetector.swiftpm
xcodegen generate
xcodebuild \
  -project NearbySignalDetector.xcodeproj \
  -scheme NearbySignalDetector \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

No paid Apple Developer membership is required for this simulator compile check. Installing on a physical iPhone still requires Apple's signing path.

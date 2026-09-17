# Nearby Signal Detector v0.4

Native SwiftUI/CoreBluetooth app for iPhone and iPad.

## Current capabilities

- Foreground BLE advertisement scanning.
- Live RSSI with exponential smoothing.
- Signal trend detection: getting stronger, steady, or getting weaker.
- Radar-style signal-strength view where radius represents received signal strength.
- Session baseline and NEW-device marking.
- Configurable strong-signal threshold with multi-observation confirmation.
- Automatic stale-device removal.
- Device search by name, iOS peripheral identifier, service UUID, or manufacturer data.
- Optional filtering of unnamed advertisements.
- Scanner preferences persisted locally with UserDefaults.
- Live RSSI history charts.
- Advertisement metadata inspection when iOS exposes it.

## Reliability changes in v0.4

The scanner now keeps previously observed names and advertisement metadata when a later advertisement omits those fields instead of replacing useful values with blanks. Scan requests also survive a temporary Bluetooth state transition and resume when Bluetooth becomes available again.

The baseline remains session-only by design. This avoids silently reusing an old set of iOS peripheral identifiers after an app restart or device-state change.

## Radar semantics

The radar is a signal-strength visualisation, not a direction finder. Stronger received BLE signals are drawn nearer the centre. The angle around the radar is only used to separate markers visually and does not represent physical direction or position.

## Important limitation

This app cannot identify police or undercover vehicles, a device owner, exact distance, direction, or an exact physical location from BLE RSSI. It also cannot scan arbitrary RF frequencies with the iPhone radio hardware.

## Cloud compile check with XcodeGen

The repository contains `project.yml`, which lets a macOS runner generate a normal Xcode project without committing a generated `.xcodeproj`.

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

No paid Apple Developer membership is required for the simulator compile check. A physical iPhone/TestFlight build still requires Apple's signing and App Store Connect path.

# Nearby Signal Detector v0.3

Native SwiftUI/CoreBluetooth prototype for iPhone and iPad.

## Current capabilities

- Foreground BLE advertisement scanning.
- Live RSSI with exponential smoothing.
- Signal trend detection: getting stronger, steady, or getting weaker.
- Dedicated radar-style live view where radius represents received signal strength.
- Session baseline and NEW-device marking.
- Configurable strong-signal threshold.
- Multi-observation confirmation before a new strong-signal alert is raised.
- Automatic stale-device removal.
- Live RSSI history charts.
- Advertisement metadata inspection when iOS exposes it.

## Radar semantics

The radar is a signal-strength visualisation, not a direction finder. Stronger received BLE signals are drawn nearer the centre. The angle around the radar is only used to separate markers visually and does not represent physical direction or position.

## Important limitation

This app cannot identify police or undercover vehicles, a device owner, exact distance, direction, or an exact physical location from BLE RSSI. It also cannot scan arbitrary RF frequencies with the iPhone radio hardware.

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

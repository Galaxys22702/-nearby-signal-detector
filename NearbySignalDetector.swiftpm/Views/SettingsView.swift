import SwiftUI

struct SettingsView: View {
    @ObservedObject var scanner: BLEScanner

    var body: some View {
        Form {
            Section("Strong-signal alert") {
                Stepper(
                    "Threshold: \(scanner.strongSignalThreshold) dBm",
                    value: $scanner.strongSignalThreshold,
                    in: -85 ... -35,
                    step: 5
                )

                Text("A new device must be at or above this received signal level before the app shows an in-app alert.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Active-device window") {
                Picker("Remove after", selection: $scanner.staleDeviceSeconds) {
                    Text("8 seconds").tag(TimeInterval(8))
                    Text("15 seconds").tag(TimeInterval(15))
                    Text("30 seconds").tag(TimeInterval(30))
                    Text("60 seconds").tag(TimeInterval(60))
                }

                Text("Devices that stop advertising are removed after this interval so the live list does not fill with stale entries.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Important limitation") {
                Text("This app measures BLE advertisements received by the iPhone. It cannot identify a police vehicle, undercover vehicle, owner, exact location, or arbitrary non-Bluetooth radio transmission.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Scanner Settings")
    }
}

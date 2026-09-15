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

                Stepper(
                    "Confirm after \(scanner.strongSignalConfirmationCount) observations",
                    value: $scanner.strongSignalConfirmationCount,
                    in: 2 ... 8
                )

                Text("A new device must stay at or above the threshold for the selected number of consecutive received advertisements before the app shows an in-app alert. This reduces one-sample RSSI spikes.")
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

            Section("Signal trend") {
                Text("Getting stronger/weaker compares the average of the newest four RSSI samples with the preceding four. Changes under 4 dB are shown as steady to reduce noise.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Important limitation") {
                Text("This app measures BLE advertisements received by the iPhone. It cannot identify a police vehicle, undercover vehicle, owner, exact distance, direction, exact location, or arbitrary non-Bluetooth radio transmission.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Scanner Settings")
    }
}

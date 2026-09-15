import SwiftUI

struct StrongSignalBanner: View {
    let alert: SignalAlert
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("New strong BLE signal")
                    .font(.headline)
                Text("\(alert.deviceName) • \(alert.rssi) dBm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss alert")
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

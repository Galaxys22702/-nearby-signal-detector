import SwiftUI

struct DeviceRow: View {
    let device: BLEDevice
    let isNew: Bool

    var body: some View {
        HStack(spacing: 12) {
            SignalBarsView(rssi: device.displayRSSI)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.headline)
                        .lineLimit(1)

                    if isNew {
                        Text("NEW")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text(device.signalLabel)

                    Label(device.signalTrend.label, systemImage: device.signalTrend.systemImage)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(device.displayRSSI) dBm")
                    .font(.system(.body, design: .monospaced).weight(.semibold))

                Text(device.lastSeen, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

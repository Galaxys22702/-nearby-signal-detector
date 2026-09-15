import SwiftUI

struct LiveDashboardView: View {
    let strongestDevice: BLEDevice?
    let deviceCount: Int
    let newDeviceCount: Int
    let isScanning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    isScanning ? "LIVE SCAN" : "SCAN STOPPED",
                    systemImage: isScanning ? "dot.radiowaves.left.and.right" : "pause.circle"
                )
                .font(.caption.bold())

                Spacer()

                Text("\(deviceCount) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let strongestDevice {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Strongest received signal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(strongestDevice.name)
                                .font(.headline)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("\(strongestDevice.displayRSSI)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("dBm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Gauge(value: strongestDevice.strengthFraction, in: 0...1) {
                        Text("Signal")
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                }
            } else {
                Text("No BLE advertisements received yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if newDeviceCount > 0 {
                Label("\(newDeviceCount) device\(newDeviceCount == 1 ? "" : "s") new since baseline", systemImage: "sparkles")
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }
}

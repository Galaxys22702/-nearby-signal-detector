import SwiftUI
import Charts

struct DeviceDetailView: View {
    @ObservedObject var scanner: BLEScanner
    let deviceID: UUID

    var body: some View {
        Group {
            if let device = scanner.device(withID: deviceID) {
                List {
                    Section("Signal") {
                        LabeledContent("Smoothed RSSI", value: "\(device.displayRSSI) dBm")
                        LabeledContent("Latest RSSI", value: "\(device.rssi) dBm")
                        LabeledContent("Signal band", value: device.signalLabel)
                        LabeledContent("Advertisements", value: "\(device.advertisementCount)")
                        LabeledContent(
                            "Baseline status",
                            value: scanner.isNewRelativeToBaseline(device) ? "New since baseline" : "Known / no baseline"
                        )
                    }

                    Section("Live history") {
                        if device.history.count >= 2 {
                            Chart(device.history) { sample in
                                LineMark(
                                    x: .value("Time", sample.timestamp),
                                    y: .value("RSSI", sample.rssi)
                                )
                            }
                            .chartYScale(domain: -100 ... -20)
                            .frame(height: 220)
                            .accessibilityLabel("RSSI history chart")
                        } else {
                            Text("More samples are needed for a graph.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Advertisement") {
                        LabeledContent("Name", value: device.name)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("iOS peripheral identifier")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.id.uuidString)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }

                        if let isConnectable = device.isConnectable {
                            LabeledContent("Connectable", value: isConnectable ? "Yes" : "No")
                        }

                        if !device.serviceUUIDs.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service UUIDs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(device.serviceUUIDs.joined(separator: "\n"))
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }

                        if let manufacturerDataHex = device.manufacturerDataHex {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Manufacturer data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(manufacturerDataHex)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    Section("Interpretation") {
                        Text("RSSI is a noisy received-signal measurement. Walls, reflections, device orientation and transmitter power can change it substantially, so it should not be treated as an exact distance measurement or proof of a device's owner or location.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle(device.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(
                    "Device no longer active",
                    systemImage: "antenna.radiowaves.left.and.right.slash",
                    description: Text("The device stopped advertising long enough to leave the live list.")
                )
            }
        }
    }
}

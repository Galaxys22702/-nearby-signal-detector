import SwiftUI
import Foundation

struct RadarView: View {
    @ObservedObject var scanner: BLEScanner

    private var displayedDevices: [BLEDevice] {
        Array(scanner.visibleDevices.prefix(10))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LiveDashboardView(
                    strongestDevice: scanner.strongestDevice,
                    deviceCount: scanner.devices.count,
                    newDeviceCount: scanner.newDeviceCount,
                    isScanning: scanner.isScanning
                )

                RadarSignalMap(
                    devices: displayedDevices,
                    baselineIDs: scanner.baselineIDs,
                    strongSignalThreshold: scanner.strongSignalThreshold
                )

                if displayedDevices.isEmpty {
                    ContentUnavailableView(
                        "No active BLE signals",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Start scanning and nearby BLE advertisers will appear here.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Radar key")
                            .font(.headline)

                        ForEach(Array(displayedDevices.prefix(5).indices), id: \.self) { index in
                            let device = displayedDevices[index]

                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .frame(width: 26, height: 26)
                                    .background(
                                        scanner.isNewRelativeToBaseline(device) ? Color.orange.opacity(0.2) : Color.accentColor.opacity(0.18),
                                        in: Circle()
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)

                                    Label(device.signalTrend.label, systemImage: device.signalTrend.systemImage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(device.displayRSSI) dBm")
                                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                            }
                        }
                    }
                }

                Text("Radar radius represents received BLE signal strength only: stronger signals are drawn nearer the centre. The angle around the circle is only for visual separation and does not represent physical direction or location.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Signal Radar")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(scanner.isScanning ? "Stop" : "Scan") {
                    if scanner.isScanning {
                        scanner.stopScanning()
                    } else {
                        scanner.startScanning()
                    }
                }

                Menu {
                    Button("Set current devices as baseline") {
                        scanner.setBaseline()
                    }
                    .disabled(scanner.devices.isEmpty)

                    Button("Clear baseline") {
                        scanner.clearBaseline()
                    }
                    .disabled(scanner.baselineIDs.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

private struct RadarSignalMap: View {
    let devices: [BLEDevice]
    let baselineIDs: Set<UUID>
    let strongSignalThreshold: Int

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, 330)
            let centre = size / 2
            let maxRadius = size * 0.44

            ZStack {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                    Circle()
                        .stroke(.secondary.opacity(0.24), lineWidth: 1)
                        .frame(width: size * fraction, height: size * fraction)
                }

                Path { path in
                    path.move(to: CGPoint(x: centre, y: 0))
                    path.addLine(to: CGPoint(x: centre, y: size))
                    path.move(to: CGPoint(x: 0, y: centre))
                    path.addLine(to: CGPoint(x: size, y: centre))
                }
                .stroke(.secondary.opacity(0.18), lineWidth: 1)

                Circle()
                    .fill(.primary)
                    .frame(width: 10, height: 10)
                    .position(x: centre, y: centre)

                ForEach(Array(devices.indices), id: \.self) { index in
                    let device = devices[index]
                    let count = max(devices.count, 1)
                    let angle = (Double(index) / Double(count) * 2.0 * Double.pi) - (Double.pi / 2.0)
                    let radius = maxRadius * device.radarRadiusFraction
                    let x = centre + CGFloat(cos(angle) * radius)
                    let y = centre + CGFloat(sin(angle) * radius)
                    let isNew = !baselineIDs.isEmpty && !baselineIDs.contains(device.id)
                    let isStrong = device.displayRSSI >= strongSignalThreshold

                    ZStack {
                        if isStrong {
                            Circle()
                                .stroke(.primary.opacity(0.55), lineWidth: 2)
                                .frame(width: 34, height: 34)
                        }

                        Circle()
                            .fill(isNew ? Color.orange : Color.accentColor)
                            .frame(width: 28, height: 28)

                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                    .position(x: x, y: y)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(device.name), \(device.displayRSSI) dBm, \(device.signalTrend.label)")
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: size / 2)
        }
        .frame(height: 340)
        .accessibilityLabel("Signal-strength radar")
    }
}

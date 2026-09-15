import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var scanner = BLEScanner()

    var body: some View {
        NavigationStack {
            Group {
                if scanner.bluetoothState == .poweredOn {
                    deviceList
                } else {
                    bluetoothUnavailableView
                }
            }
            .navigationTitle("Nearby Signals")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(scanner: scanner)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
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

                        Divider()

                        Toggle("Show only new", isOn: $scanner.showOnlyNew)
                            .disabled(scanner.baselineIDs.isEmpty)

                        Divider()

                        Button("Clear scan results", role: .destructive) {
                            scanner.clearDevices()
                        }
                        .disabled(scanner.devices.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button(scanner.isScanning ? "Stop" : "Scan") {
                        if scanner.isScanning {
                            scanner.stopScanning()
                        } else {
                            scanner.startScanning()
                        }
                    }
                }
            }
        }
    }

    private var deviceList: some View {
        List {
            if let alert = scanner.latestAlert {
                Section {
                    StrongSignalBanner(alert: alert) {
                        scanner.dismissAlert()
                    }
                }
            }

            Section {
                LiveDashboardView(
                    strongestDevice: scanner.strongestDevice,
                    deviceCount: scanner.devices.count,
                    newDeviceCount: scanner.newDeviceCount,
                    isScanning: scanner.isScanning
                )

                if scanner.baselineIDs.isEmpty {
                    Text("Scan for a while, then set the current devices as your baseline. Devices first observed afterwards are marked NEW.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Baseline contains \(scanner.baselineIDs.count) device identifiers. Strong new-signal threshold: \(scanner.strongSignalThreshold) dBm.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(scanner.showOnlyNew ? "New since baseline" : "Strongest first") {
                if scanner.visibleDevices.isEmpty {
                    ContentUnavailableView(
                        scanner.showOnlyNew ? "No new active devices" : "No BLE advertisements yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text(scanner.showOnlyNew ? "New devices will appear here while scanning." : "Tap Scan and keep the app open while nearby Bluetooth Low Energy devices advertise.")
                    )
                } else {
                    ForEach(scanner.visibleDevices) { device in
                        NavigationLink {
                            DeviceDetailView(scanner: scanner, deviceID: device.id)
                        } label: {
                            DeviceRow(
                                device: device,
                                isNew: scanner.isNewRelativeToBaseline(device)
                            )
                        }
                    }
                }
            }

            Section("What this means") {
                Text("A stronger RSSI generally means the received Bluetooth signal is stronger at this iPhone. It does not establish exact distance, which car transmitted it, or who owns it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var bluetoothUnavailableView: some View {
        ContentUnavailableView(
            "Bluetooth unavailable",
            systemImage: "bluetooth.slash",
            description: Text(bluetoothStateMessage)
        )
    }

    private var bluetoothStateMessage: String {
        switch scanner.bluetoothState {
        case .poweredOff:
            return "Turn Bluetooth on in Settings or Control Centre."
        case .unauthorized:
            return "Allow Bluetooth access for this app in Settings."
        case .unsupported:
            return "This device does not support the required Bluetooth features."
        case .resetting:
            return "Bluetooth is resetting."
        case .unknown:
            return "Checking Bluetooth status…"
        case .poweredOn:
            return "Bluetooth is ready."
        @unknown default:
            return "Bluetooth status is unavailable."
        }
    }
}

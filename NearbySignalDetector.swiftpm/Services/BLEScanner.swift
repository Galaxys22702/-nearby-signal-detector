import Foundation
import CoreBluetooth

final class BLEScanner: NSObject, ObservableObject {
    @Published private(set) var devices: [BLEDevice] = []
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var isScanning = false
    @Published private(set) var baselineIDs: Set<UUID> = []
    @Published private(set) var latestAlert: SignalAlert?

    @Published var strongSignalThreshold = -55
    @Published var strongSignalConfirmationCount = 3
    @Published var staleDeviceSeconds: TimeInterval = 15
    @Published var showOnlyNew = false

    private var centralManager: CBCentralManager!
    private var devicesByID: [UUID: BLEDevice] = [:]
    private var alertedStrongIDs: Set<UUID> = []
    private var strongObservationCounts: [UUID: Int] = [:]
    private var cleanupTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    var visibleDevices: [BLEDevice] {
        guard showOnlyNew, !baselineIDs.isEmpty else { return devices }
        return devices.filter { !baselineIDs.contains($0.id) }
    }

    var strongestDevice: BLEDevice? {
        devices.first
    }

    var newDeviceCount: Int {
        guard !baselineIDs.isEmpty else { return 0 }
        return devices.reduce(into: 0) { count, device in
            if !baselineIDs.contains(device.id) {
                count += 1
            }
        }
    }

    var strongNewDeviceCount: Int {
        guard !baselineIDs.isEmpty else { return 0 }
        return devices.reduce(into: 0) { count, device in
            if !baselineIDs.contains(device.id), device.displayRSSI >= strongSignalThreshold {
                count += 1
            }
        }
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    func clearDevices() {
        devicesByID.removeAll()
        devices.removeAll()
        alertedStrongIDs.removeAll()
        strongObservationCounts.removeAll()
        latestAlert = nil
    }

    func setBaseline() {
        baselineIDs = Set(devicesByID.keys)
        alertedStrongIDs.removeAll()
        strongObservationCounts.removeAll()
        latestAlert = nil
    }

    func clearBaseline() {
        baselineIDs.removeAll()
        alertedStrongIDs.removeAll()
        strongObservationCounts.removeAll()
        latestAlert = nil
    }

    func dismissAlert() {
        latestAlert = nil
    }

    func isNewRelativeToBaseline(_ device: BLEDevice) -> Bool {
        !baselineIDs.isEmpty && !baselineIDs.contains(device.id)
    }

    func device(withID id: UUID) -> BLEDevice? {
        devicesByID[id]
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.removeStaleDevices()
        }
    }

    private func removeStaleDevices(now: Date = Date()) {
        let staleIDs = devicesByID.compactMap { id, device in
            now.timeIntervalSince(device.lastSeen) > staleDeviceSeconds ? id : nil
        }

        guard !staleIDs.isEmpty else { return }

        for id in staleIDs {
            devicesByID.removeValue(forKey: id)
            alertedStrongIDs.remove(id)
            strongObservationCounts.removeValue(forKey: id)
        }
        publishDevices()
    }

    private func evaluateStrongNewSignal(_ device: BLEDevice) {
        let id = device.id

        guard !baselineIDs.isEmpty,
              !baselineIDs.contains(id),
              !alertedStrongIDs.contains(id) else {
            strongObservationCounts[id] = 0
            return
        }

        guard device.displayRSSI >= strongSignalThreshold else {
            strongObservationCounts[id] = 0
            return
        }

        let observationCount = (strongObservationCounts[id] ?? 0) + 1
        strongObservationCounts[id] = observationCount

        let requiredCount = max(1, strongSignalConfirmationCount)
        guard observationCount >= requiredCount,
              device.advertisementCount >= requiredCount else {
            return
        }

        alertedStrongIDs.insert(id)
        latestAlert = SignalAlert(
            deviceID: id,
            deviceName: device.name,
            rssi: device.displayRSSI,
            timestamp: Date()
        )
    }

    private func publishDevices() {
        devices = devicesByID.values.sorted {
            if $0.smoothedRSSI == $1.smoothedRSSI {
                return $0.lastSeen > $1.lastSeen
            }
            return $0.smoothedRSSI > $1.smoothedRSSI
        }
    }

    private func hexString(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

extension BLEScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        if central.state != .poweredOn {
            isScanning = false
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rawRSSI = RSSI.intValue
        guard rawRSSI != 127 else { return }

        let identifier = peripheral.identifier
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = localName ?? peripheral.name ?? "Unknown BLE device"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map(\.uuidString) ?? []
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        let now = Date()

        if var existing = devicesByID[identifier] {
            let alpha = 0.28
            existing.rssi = rawRSSI
            existing.smoothedRSSI = alpha * Double(rawRSSI) + (1 - alpha) * existing.smoothedRSSI
            existing.lastSeen = now
            existing.advertisementCount += 1
            existing.name = name
            existing.serviceUUIDs = services
            existing.manufacturerDataHex = hexString(from: manufacturerData)
            existing.isConnectable = isConnectable
            existing.history.append(SignalSample(timestamp: now, rssi: rawRSSI))

            if existing.history.count > 120 {
                existing.history.removeFirst(existing.history.count - 120)
            }

            devicesByID[identifier] = existing
            evaluateStrongNewSignal(existing)
        } else {
            let device = BLEDevice(
                id: identifier,
                name: name,
                rssi: rawRSSI,
                smoothedRSSI: Double(rawRSSI),
                firstSeen: now,
                lastSeen: now,
                advertisementCount: 1,
                serviceUUIDs: services,
                manufacturerDataHex: hexString(from: manufacturerData),
                isConnectable: isConnectable,
                history: [SignalSample(timestamp: now, rssi: rawRSSI)]
            )
            devicesByID[identifier] = device
            evaluateStrongNewSignal(device)
        }

        publishDevices()
    }
}

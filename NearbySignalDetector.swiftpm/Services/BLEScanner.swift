import Foundation
import CoreBluetooth

final class BLEScanner: NSObject, ObservableObject {
    private enum PreferenceKey {
        static let strongSignalThreshold = "strongSignalThreshold"
        static let strongSignalConfirmationCount = "strongSignalConfirmationCount"
        static let staleDeviceSeconds = "staleDeviceSeconds"
        static let hideUnnamedDevices = "hideUnnamedDevices"
    }

    @Published private(set) var devices: [BLEDevice] = []
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var isScanning = false
    @Published private(set) var baselineIDs: Set<UUID> = []
    @Published private(set) var baselineDate: Date?
    @Published private(set) var latestAlert: SignalAlert?

    @Published var strongSignalThreshold = -55 {
        didSet {
            UserDefaults.standard.set(strongSignalThreshold, forKey: PreferenceKey.strongSignalThreshold)
        }
    }

    @Published var strongSignalConfirmationCount = 3 {
        didSet {
            UserDefaults.standard.set(strongSignalConfirmationCount, forKey: PreferenceKey.strongSignalConfirmationCount)
        }
    }

    @Published var staleDeviceSeconds: TimeInterval = 15 {
        didSet {
            UserDefaults.standard.set(staleDeviceSeconds, forKey: PreferenceKey.staleDeviceSeconds)
        }
    }

    @Published var showOnlyNew = false

    @Published var hideUnnamedDevices = false {
        didSet {
            UserDefaults.standard.set(hideUnnamedDevices, forKey: PreferenceKey.hideUnnamedDevices)
        }
    }

    private var centralManager: CBCentralManager!
    private var devicesByID: [UUID: BLEDevice] = [:]
    private var alertedStrongIDs: Set<UUID> = []
    private var strongObservationCounts: [UUID: Int] = [:]
    private var cleanupTimer: Timer?
    private var scanRequested = false

    override init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: PreferenceKey.strongSignalThreshold) != nil {
            strongSignalThreshold = min(max(defaults.integer(forKey: PreferenceKey.strongSignalThreshold), -95), -30)
        }
        if defaults.object(forKey: PreferenceKey.strongSignalConfirmationCount) != nil {
            strongSignalConfirmationCount = min(max(defaults.integer(forKey: PreferenceKey.strongSignalConfirmationCount), 1), 10)
        }
        if defaults.object(forKey: PreferenceKey.staleDeviceSeconds) != nil {
            staleDeviceSeconds = min(max(defaults.double(forKey: PreferenceKey.staleDeviceSeconds), 5), 120)
        }
        if defaults.object(forKey: PreferenceKey.hideUnnamedDevices) != nil {
            hideUnnamedDevices = defaults.bool(forKey: PreferenceKey.hideUnnamedDevices)
        }

        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    var visibleDevices: [BLEDevice] {
        var result = devices

        if hideUnnamedDevices {
            result = result.filter { $0.name != "Unknown BLE device" }
        }

        if showOnlyNew, !baselineIDs.isEmpty {
            result = result.filter { !baselineIDs.contains($0.id) }
        }

        return result
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

    func startScanning() {
        scanRequested = true
        beginScanIfPossible()
    }

    func stopScanning() {
        scanRequested = false
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
        baselineDate = Date()
        alertedStrongIDs.removeAll()
        strongObservationCounts.removeAll()
        latestAlert = nil
    }

    func clearBaseline() {
        baselineIDs.removeAll()
        baselineDate = nil
        alertedStrongIDs.removeAll()
        strongObservationCounts.removeAll()
        latestAlert = nil
        showOnlyNew = false
    }

    func resetSettings() {
        strongSignalThreshold = -55
        strongSignalConfirmationCount = 3
        staleDeviceSeconds = 15
        showOnlyNew = false
        hideUnnamedDevices = false
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

    private func beginScanIfPossible() {
        guard scanRequested,
              centralManager.state == .poweredOn,
              !isScanning else {
            return
        }

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
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

        if let alertID = latestAlert?.deviceID, staleIDs.contains(alertID) {
            latestAlert = nil
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

    private func sanitizedName(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func hexString(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

extension BLEScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        if central.state == .poweredOn {
            beginScanIfPossible()
        } else {
            central.stopScan()
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
        let advertisedName = sanitizedName(localName) ?? sanitizedName(peripheral.name)
        let services = Array(
            Set(
                ((advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? [])
                    .map(\.uuidString)
            )
        ).sorted()
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let manufacturerDataHex = hexString(from: manufacturerData)
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectableKey] as? NSNumber)?.boolValue
        let now = Date()

        if var existing = devicesByID[identifier] {
            let alpha = 0.28
            existing.rssi = rawRSSI
            existing.smoothedRSSI = alpha * Double(rawRSSI) + (1 - alpha) * existing.smoothedRSSI
            existing.lastSeen = now
            existing.advertisementCount += 1

            if let advertisedName {
                existing.name = advertisedName
            }
            if !services.isEmpty {
                existing.serviceUUIDs = services
            }
            if let manufacturerDataHex {
                existing.manufacturerDataHex = manufacturerDataHex
            }
            if let isConnectable {
                existing.isConnectable = isConnectable
            }

            existing.history.append(SignalSample(timestamp: now, rssi: rawRSSI))

            if existing.history.count > 120 {
                existing.history.removeFirst(existing.history.count - 120)
            }

            devicesByID[identifier] = existing
            evaluateStrongNewSignal(existing)
        } else {
            let device = BLEDevice(
                id: identifier,
                name: advertisedName ?? "Unknown BLE device",
                rssi: rawRSSI,
                smoothedRSSI: Double(rawRSSI),
                firstSeen: now,
                lastSeen: now,
                advertisementCount: 1,
                serviceUUIDs: services,
                manufacturerDataHex: manufacturerDataHex,
                isConnectable: isConnectable,
                history: [SignalSample(timestamp: now, rssi: rawRSSI)]
            )
            devicesByID[identifier] = device
            evaluateStrongNewSignal(device)
        }

        publishDevices()
    }
}

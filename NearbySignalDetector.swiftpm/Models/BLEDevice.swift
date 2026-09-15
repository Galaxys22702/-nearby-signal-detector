import Foundation

struct BLEDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rssi: Int
    var smoothedRSSI: Double
    let firstSeen: Date
    var lastSeen: Date
    var advertisementCount: Int
    var serviceUUIDs: [String]
    var manufacturerDataHex: String?
    var isConnectable: Bool?
    var history: [SignalSample]

    var displayRSSI: Int {
        Int(smoothedRSSI.rounded())
    }

    var signalLabel: String {
        switch displayRSSI {
        case -50...:
            return "Very strong"
        case -65 ..< -50:
            return "Strong"
        case -80 ..< -65:
            return "Moderate"
        default:
            return "Weak"
        }
    }

    var strengthFraction: Double {
        let bounded = min(max(Double(displayRSSI), -100), -30)
        return (bounded + 100) / 70
    }
}

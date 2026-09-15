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

    var radarRadiusFraction: Double {
        min(max(1.0 - (strengthFraction * 0.82), 0.14), 0.92)
    }

    var trendDelta: Double {
        guard history.count >= 8 else { return 0 }

        let samples = Array(history.suffix(8))
        let olderAverage = samples.prefix(4).reduce(0.0) { $0 + Double($1.rssi) } / 4.0
        let newerAverage = samples.suffix(4).reduce(0.0) { $0 + Double($1.rssi) } / 4.0
        return newerAverage - olderAverage
    }

    var signalTrend: SignalTrend {
        guard history.count >= 8 else { return .unknown }

        switch trendDelta {
        case 4...:
            return .rising
        case ...(-4):
            return .falling
        default:
            return .steady
        }
    }
}

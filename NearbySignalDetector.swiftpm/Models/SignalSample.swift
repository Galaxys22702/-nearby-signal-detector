import Foundation

struct SignalSample: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let rssi: Int
}

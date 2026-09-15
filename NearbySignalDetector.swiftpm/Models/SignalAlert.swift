import Foundation

struct SignalAlert: Identifiable, Equatable {
    let id = UUID()
    let deviceID: UUID
    let deviceName: String
    let rssi: Int
    let timestamp: Date
}

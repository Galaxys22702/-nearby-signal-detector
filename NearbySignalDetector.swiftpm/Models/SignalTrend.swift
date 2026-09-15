import Foundation

enum SignalTrend: String, Hashable {
    case rising
    case steady
    case falling
    case unknown

    var label: String {
        switch self {
        case .rising:
            return "Getting stronger"
        case .steady:
            return "Steady"
        case .falling:
            return "Getting weaker"
        case .unknown:
            return "Collecting samples"
        }
    }

    var systemImage: String {
        switch self {
        case .rising:
            return "arrow.up.right"
        case .steady:
            return "arrow.right"
        case .falling:
            return "arrow.down.right"
        case .unknown:
            return "ellipsis"
        }
    }
}

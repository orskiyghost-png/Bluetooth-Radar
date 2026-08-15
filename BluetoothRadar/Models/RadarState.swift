import Foundation

enum RadarTrackingState: Equatable {
    case tracking
    case lost
    case stopped

    var title: String {
        switch self {
        case .tracking: return "TRACKING"
        case .lost: return "LOST"
        case .stopped: return "STOPPED"
        }
    }
}

enum SmoothingSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"

    var id: String { rawValue }
    var alpha: Double {
        switch self {
        case .slow: return 0.2
        case .normal: return 0.3
        case .fast: return 0.5
        }
    }
}

enum LostTimeout: Double, CaseIterable, Identifiable {
    case two = 2
    case three = 3
    case five = 5

    var id: Double { rawValue }
    var label: String { "\(Int(rawValue)) sec" }
}

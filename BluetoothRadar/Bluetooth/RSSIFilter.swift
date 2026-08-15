import Foundation

struct RSSIFilter {
    var alpha: Double
    private(set) var value: Double?

    init(alpha: Double = 0.3) {
        self.alpha = min(max(alpha, 0.01), 1.0)
        self.value = nil
    }

    mutating func update(with current: Double) -> Double {
        guard current.isFinite else { return value ?? -100 }
        let next = value.map { alpha * current + (1 - alpha) * $0 } ?? current
        value = next
        return next
    }

    mutating func reset() { value = nil }
}

struct RSSIMapper {
    static let minimum = -100.0
    static let maximum = -50.0

    static func normalized(_ rssi: Double) -> Double {
        guard rssi.isFinite else { return 0 }
        return min(max((rssi - minimum) / (maximum - minimum), 0), 1)
    }

    static func signalLevel(for rssi: Double) -> SignalLevel {
        switch normalized(rssi) {
        case 0..<0.2: return .veryWeak
        case 0.2..<0.4: return .weak
        case 0.4..<0.6: return .medium
        case 0.6..<0.8: return .strong
        default: return .veryStrong
        }
    }
}

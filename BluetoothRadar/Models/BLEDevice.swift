import CoreBluetooth
import Foundation

enum SignalLevel: String, CaseIterable, Codable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    case veryStrong = "Very Strong"

    var colorName: String {
        switch self {
        case .veryWeak: return "gray"
        case .weak: return "orange"
        case .medium: return "yellow"
        case .strong: return "mint"
        case .veryStrong: return "green"
        }
    }
}

struct RSSISample: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

struct BLEDevice: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int
    var smoothedRSSI: Double
    var lastSeen: Date
    var isLost: Bool
    var signalLevel: SignalLevel
    var history: [RSSISample]

    init(peripheral: CBPeripheral, rssi: Int, now: Date = .now) {
        self.id = peripheral.identifier
        self.name = peripheral.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? peripheral.name! : "Unnamed device"
        self.rssi = rssi
        self.smoothedRSSI = Double(rssi)
        self.lastSeen = now
        self.isLost = false
        self.signalLevel = RSSIMapper.signalLevel(for: Double(rssi))
        self.history = [RSSISample(timestamp: now, value: Double(rssi))]
    }

    var shortIdentifier: String {
        let value = id.uuidString
        return value.count > 13 ? String(value.prefix(8)) + "…" + String(value.suffix(4)) : value
    }
}

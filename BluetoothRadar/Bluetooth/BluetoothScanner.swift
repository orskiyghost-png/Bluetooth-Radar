import CoreBluetooth
import Foundation

@MainActor
final class BluetoothScanner: NSObject, ObservableObject {
    @Published private(set) var devices: [UUID: BLEDevice] = [:]
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var statusMessage = "Checking Bluetooth…"

    private var central: CBCentralManager!
    private let lostTimeout: TimeInterval = 3
    var alpha: Double = 0.3

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard bluetoothState == .poweredOn else { return }
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScanning() {
        central.stopScan()
    }

    func clearDevices() {
        devices.removeAll()
    }

    func markLostDevices(now: Date = .now) {
        for id in devices.keys {
            guard let device = devices[id], !device.isLost else { continue }
            if now.timeIntervalSince(device.lastSeen) >= lostTimeout {
                devices[id]?.isLost = true
            }
        }
    }

    private func update(_ peripheral: CBPeripheral, rssi: Int, now: Date) {
        if var existing = devices[peripheral.identifier] {
            let previous = existing.smoothedRSSI
            existing.name = peripheral.name?.isEmpty == false ? peripheral.name! : existing.name
            existing.rssi = rssi
            existing.smoothedRSSI = alpha * Double(rssi) + (1 - alpha) * previous
            existing.lastSeen = now
            existing.isLost = false
            existing.signalLevel = RSSIMapper.signalLevel(for: existing.smoothedRSSI)
            existing.history.append(RSSISample(timestamp: now, value: Double(rssi)))
            let cutoff = now.addingTimeInterval(-20)
            existing.history = existing.history.filter { $0.timestamp >= cutoff }
            devices[peripheral.identifier] = existing
        } else {
            devices[peripheral.identifier] = BLEDevice(peripheral: peripheral, rssi: rssi, now: now)
        }
    }
}

extension BluetoothScanner: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.bluetoothState = central.state
            switch central.state {
            case .poweredOn:
                self.statusMessage = "Bluetooth ready"
                self.startScanning()
            case .poweredOff: self.statusMessage = "Bluetooth is turned off"
            case .unauthorized: self.statusMessage = "Bluetooth permission denied"
            case .unsupported: self.statusMessage = "Bluetooth is not supported"
            case .resetting: self.statusMessage = "Bluetooth is resetting"
            case .unknown: self.statusMessage = "Bluetooth state is unknown"
            @unknown default: self.statusMessage = "Unknown Bluetooth state"
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            self.update(peripheral, rssi: RSSI.intValue, now: .now)
        }
    }
}

import CoreBluetooth
import Foundation

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published private(set) var scanner: BluetoothScanner
    @Published var selectedDeviceID: UUID?
    @Published var showSettings = false
    @Published var hapticsEnabled = true { didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") } }
    @Published var smoothingSpeed: SmoothingSpeed = .normal { didSet { scanner.alpha = smoothingSpeed.alpha } }
    @Published var lostTimeout: LostTimeout = .three

    init(scanner: BluetoothScanner = BluetoothScanner()) {
        self.scanner = scanner
        hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    var devices: [BLEDevice] {
        scanner.devices.values.sorted { $0.lastSeen > $1.lastSeen }
    }

    func refresh() { scanner.startScanning() }
    func select(_ device: BLEDevice) { selectedDeviceID = device.id }
    func device(for id: UUID) -> BLEDevice? { scanner.devices[id] }
    func tick() { scanner.markLostDevices() }
}

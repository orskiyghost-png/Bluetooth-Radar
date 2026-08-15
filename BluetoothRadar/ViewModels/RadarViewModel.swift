import Foundation

@MainActor
final class RadarViewModel: ObservableObject {
    @Published private(set) var device: BLEDevice?
    @Published private(set) var state: RadarTrackingState = .stopped
    @Published private(set) var demoMode = false
    @Published private(set) var demoRSSI = -72.0

    private var timer: Timer?
    private let scanner: ScannerViewModel

    init(scanner: ScannerViewModel) { self.scanner = scanner }

    var currentRSSI: Double { demoMode ? demoRSSI : (device?.smoothedRSSI ?? -100) }
    var currentLevel: SignalLevel { RSSIMapper.signalLevel(for: currentRSSI) }
    var history: [RSSISample] { device?.history ?? [RSSISample(timestamp: .now, value: demoRSSI)] }

    func start(deviceID: UUID) {
        demoMode = false
        device = scanner.device(for: deviceID)
        state = .tracking
        beginTimer()
    }

    func startDemo() {
        demoMode = true
        state = .tracking
        demoRSSI = -72
        beginTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .stopped
        demoMode = false
    }

    func refresh() {
        guard !demoMode else { return }
        device = device.flatMap { scanner.device(for: $0.id) }
        if let device { state = device.isLost ? .lost : .tracking }
    }

    private func beginTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.demoMode {
                self.demoRSSI = min(max(self.demoRSSI + Double.random(in: -3...3), -98), -52)
            } else { self.refresh() }
        }
    }
}

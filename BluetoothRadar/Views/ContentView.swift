import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @State private var selectedID: UUID?
    @State private var showRadar = false
    @State private var showDemo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle().fill(scanner.scanner.bluetoothState == .poweredOn ? .green : .orange).frame(width: 9)
                        Text(scanner.scanner.statusMessage)
                        Spacer()
                        Button("Scan") { scanner.refresh() }
                    }
                }
                Section("Nearby devices") {
                    if scanner.devices.isEmpty {
                        ContentUnavailableView("No BLE devices", systemImage: "dot.radiowaves.left.and.right", description: Text("Move near an advertising BLE device and scan again."))
                    } else {
                        ForEach(scanner.devices) { device in
                            Button { selectedID = device.id; showRadar = true } label: { DeviceRow(device: device) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Button { showDemo = true } label: { Label("Demo Radar", systemImage: "dot.scope") }
                }
            }
            .navigationTitle("Bluetooth Radar")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { scanner.showSettings = true } label: { Image(systemName: "gear") } } }
            .navigationDestination(isPresented: $showRadar) {
                if let selectedID { RadarView(viewModel: RadarViewModel(scanner: scanner), deviceID: selectedID) }
            }
            .navigationDestination(isPresented: $showDemo) { RadarView(viewModel: RadarViewModel(scanner: scanner), demo: true) }
            .sheet(isPresented: $scanner.showSettings) { SettingsView() }
            .task { scanner.refresh() }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in scanner.tick() }
        }
    }
}

struct DeviceRow: View {
    let device: BLEDevice
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "dot.radiowaves.left.and.right").font(.title2).foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name).font(.headline)
                Text(device.shortIdentifier).font(.caption.monospaced()).foregroundStyle(.secondary)
                Text("Signal: \(device.signalLevel.rawValue)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(device.rssi) dBm").font(.subheadline.monospacedDigit())
                Text(device.isLost ? "LOST" : "LIVE").font(.caption2).foregroundStyle(device.isLost ? .red : .green)
            }
        }.padding(.vertical, 5)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section("RSSI smoothing") { Picker("Speed", selection: $scanner.smoothingSpeed) { ForEach(SmoothingSpeed.allCases) { Text($0.rawValue).tag($0) } } }
                Section("Tracking") { Picker("Lost timeout", selection: $scanner.lostTimeout) { ForEach(LostTimeout.allCases) { Text($0.label).tag($0) } } }
                Section("Feedback") { Toggle("Haptics", isOn: $scanner.hapticsEnabled) }
                Section("About") { Text("Bluetooth Radar uses local CoreBluetooth advertisements and RSSI as a relative proximity indicator. It does not estimate exact distance or direction.") }
            }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
        }
    }
}

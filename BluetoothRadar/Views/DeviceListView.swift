import SwiftUI

struct DeviceListView: View {
    let devices: [BLEDevice]
    let onSelect: (BLEDevice) -> Void

    var body: some View {
        List(devices) { device in
            Button { onSelect(device) } label: { DeviceRow(device: device) }
                .buttonStyle(.plain)
        }
    }
}

struct SignalStrengthView: View {
    let level: SignalLevel
    var body: some View {
        Label(level.rawValue, systemImage: "wifi")
            .foregroundStyle(level == .veryWeak ? .orange : .cyan)
    }
}

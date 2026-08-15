import SwiftUI

@main
struct BluetoothRadarApp: App {
    @StateObject private var scanner = ScannerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanner)
                .preferredColorScheme(.dark)
        }
    }
}

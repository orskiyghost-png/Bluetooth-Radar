import SwiftUI

struct RadarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RadarViewModel
    let deviceID: UUID?
    let demo: Bool
    @State private var pulsing = false

    init(viewModel: RadarViewModel, deviceID: UUID? = nil, demo: Bool = false) {
        self.viewModel = viewModel
        self.deviceID = deviceID
        self.demo = demo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Label(viewModel.state.title, systemImage: viewModel.state == .tracking ? "location.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(viewModel.state == .tracking ? .green : .orange).font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.demoMode ? "DEMO" : (viewModel.device?.name ?? "Selected device")).foregroundStyle(.secondary)
                }
                RadarCanvas(normalized: RSSIMapper.normalized(viewModel.currentRSSI), lost: viewModel.state == .lost, pulsing: pulsing)
                    .frame(height: 330)
                VStack(spacing: 6) {
                    Text("\(Int(viewModel.currentRSSI.rounded())) dBm").font(.system(size: 34, weight: .semibold, design: .monospaced))
                    Text("Signal: \(viewModel.currentLevel.rawValue)").foregroundStyle(.cyan)
                    if viewModel.state == .lost { Text("Waiting for signal…").foregroundStyle(.orange) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("RSSI history").font(.headline); Spacer(); Text("last 20 sec").font(.caption).foregroundStyle(.secondary) }
                    RSSIHistoryGraph(samples: viewModel.history).frame(height: 80).padding(10).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }
                Button(role: .destructive) { viewModel.stop(); dismiss() } label: { Label("Stop Tracking", systemImage: "stop.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent)
            }.padding()
        }
        .navigationTitle("Radar").navigationBarTitleDisplayMode(.inline)
        .task {
            if demo { viewModel.startDemo() } else if let deviceID { viewModel.start(deviceID: deviceID) }
            pulsing = true
        }
        .onDisappear { viewModel.stop() }
    }
}

struct RadarCanvas: View {
    let normalized: Double
    let lost: Bool
    let pulsing: Bool

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) * 0.42
            let distance = radius * (1 - normalized)
            ZStack {
                ForEach(1...5, id: \.self) { index in Circle().stroke(.cyan.opacity(0.16), lineWidth: 1).frame(width: radius * 2 * CGFloat(index) / 5, height: radius * 2 * CGFloat(index) / 5) }
                Path { path in path.move(to: CGPoint(x: center.x, y: center.y - radius)); path.addLine(to: CGPoint(x: center.x, y: center.y + radius)); path.move(to: CGPoint(x: center.x - radius, y: center.y)); path.addLine(to: CGPoint(x: center.x + radius, y: center.y)) }.stroke(.cyan.opacity(0.12), lineWidth: 1)
                Circle().fill(.white).frame(width: 14, height: 14).shadow(color: .cyan, radius: 8).position(center)
                Circle().fill(lost ? .gray : .cyan).frame(width: lost ? 13 : 18, height: lost ? 13 : 18).shadow(color: lost ? .clear : .cyan, radius: pulsing ? 14 : 5).opacity(lost ? 0.35 : 1).position(x: center.x, y: center.y - distance)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(.cyan.opacity(0.2)))
    }
}

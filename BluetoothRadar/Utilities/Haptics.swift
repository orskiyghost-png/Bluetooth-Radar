import SwiftUI
import UIKit

struct Haptics {
    static func signalTransition(from old: SignalLevel, to new: SignalLevel, enabled: Bool) {
        guard enabled else { return }
        let order = SignalLevel.allCases
        guard let oldIndex = order.firstIndex(of: old), let newIndex = order.firstIndex(of: new), newIndex > oldIndex else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct RSSIHistoryGraph: View {
    let samples: [RSSISample]

    var body: some View {
        GeometryReader { proxy in
            let points = samples.map { sample -> CGPoint in
                let x = CGFloat(samples.first.map { sample.timestamp.timeIntervalSince($0.timestamp) } ?? 0) / 20 * proxy.size.width
                let y = proxy.size.height * (1 - CGFloat(RSSIMapper.normalized(sample.value)))
                return CGPoint(x: min(max(x, 0), proxy.size.width), y: y)
            }
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
            }
            .stroke(.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

import SwiftUI

struct SignalBarsView: View {
    let rssi: Int

    private var activeBars: Int {
        switch rssi {
        case -50...: return 4
        case -65 ..< -50: return 3
        case -80 ..< -65: return 2
        default: return 1
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { index in
                Capsule()
                    .fill(index <= activeBars ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: 4, height: CGFloat(index) * 5)
            }
        }
        .frame(width: 24, height: 22)
        .accessibilityLabel("Signal strength")
        .accessibilityValue("\(activeBars) of 4")
    }
}

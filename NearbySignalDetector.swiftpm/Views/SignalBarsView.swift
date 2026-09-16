import SwiftUI

struct SignalBarsView: View {
    let rssi: Int

    private var activeBars: Int {
        if rssi >= -50 {
            return 4
        }
        if rssi >= -65 {
            return 3
        }
        if rssi >= -80 {
            return 2
        }
        return 1
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

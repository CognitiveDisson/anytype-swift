import SwiftUI

struct PositionCatcher: View {
    let onChange: (CGPoint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: PositionCatcherKey.self,
                value: geometry.frame(in: .global)
            )
        }
        .frame(width: 0, height: 0)
        .onPreferenceChange(PositionCatcherKey.self) {
            onChange($0.origin)
        }
    }
}

struct PositionCatcherKey: PreferenceKey {
    static var defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

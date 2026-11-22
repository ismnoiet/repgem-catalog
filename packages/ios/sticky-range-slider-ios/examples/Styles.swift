import SwiftUI
import StickyRangeSlider

struct Styles: View {
    @State private var lower = 40
    @State private var upper = 140

    var body: some View {
        VStack(spacing: 28) {
            // On a light surface (default) and on a dark one.
            StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...200, style: .ink)
            StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...200, style: .paper)

            // Any color.
            StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...200, style: .accent(.blue))

            // Or build your own.
            StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...200, style: StickySliderStyle(
                pill: .indigo, label: .white,
                track: .indigo.opacity(0.2), trackFill: .indigo,
                shadow: .indigo.opacity(0.4)
            ))
        }
    }
}

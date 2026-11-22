import SwiftUI
import StickyRangeSlider

struct PriceFilter: View {
    @State private var lower = 85
    @State private var upper = 240

    var body: some View {
        StickyRangeSlider(lower: $lower, upper: $upper, bounds: 20...400, step: 5)
            .padding(.horizontal)
    }
}

struct DistanceFilter: View {
    @State private var distance = 12

    var body: some View {
        // One handle, other units.
        StickyRangeSlider(value: $distance, bounds: 1...50, step: 1, prefix: "", suffix: " km")
    }
}

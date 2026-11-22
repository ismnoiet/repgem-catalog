import SwiftUI
import StickyRangeSlider

struct Timing: View {
    @State private var lower = 85
    @State private var upper = 240

    var body: some View {
        // Heavy, lazy handles. Every value is a spring response in seconds.
        StickyRangeSlider(
            lower: $lower, upper: $upper,
            timing: StickyTiming(follow: 0.45, glide: 0.6)
        ) { isEditing in
            // true when a drag starts, false when it ends
            if !isEditing { print("search", lower...upper) }
        }
    }
}

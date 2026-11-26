import SwiftUI
import FireworkFlourish

// Pick a preset, or build your own style from any palette.
struct StyleExamples: View {
    var isToday = true

    var custom: FireworkStyle {
        FireworkStyle(interval: 0.2, particles: 90, maxRadius: 60, palettes: FireworkPalette.gold)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Today").overlay { FireworkFlourish(.sparkle, active: isToday) }   // pauses when inactive
            Text("Level up").overlay { FireworkFlourish(custom) }
        }
        .foregroundStyle(.white)
    }
}

// On a light surface, switch to the light look (normal blending, deeper colors).
struct LightCard: View {
    var body: some View {
        Color.white
            .overlay { FireworkFlourish(.card) }
            .fireworkLightBackground()
    }
}

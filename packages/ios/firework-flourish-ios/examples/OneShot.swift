import SwiftUI
import FireworkFlourish

// A celebration that plays once per trigger change, then stops costing anything.
struct GoalButton: View {
    @State private var goals = 0

    var body: some View {
        Button("Home scores") { goals += 1 }
            .buttonStyle(.borderedProminent)
            .fireworkFlourish(trigger: goals, duration: 1.8, style: .neonPop)
    }
}

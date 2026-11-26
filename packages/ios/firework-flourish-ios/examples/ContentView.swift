import SwiftUI
import FireworkFlourish

// Fireworks over a card. Clip the layer to the shape that should hold them.
struct AnniversaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Anniversary · Alex & Sam").font(.footnote).foregroundStyle(.white.opacity(0.6))
            Text("5 years today").font(.largeTitle.bold()).foregroundStyle(.white)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.2, green: 0.08, blue: 0.16))
        .overlay { FireworkFlourish(.romance) }                       // runs while it is on screen
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

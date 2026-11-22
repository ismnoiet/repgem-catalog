import DustDissolve

// Ready-made looks: .coupon, .snap, .dismiss, .fall, .burst
struct DeleteRow: View {
    @StateObject private var dust: DustDissolveController = {
        var config = DustDissolveConfiguration.fall
        config.particleCount = 700
        return DustDissolveController(config)
    }()

    var body: some View {
        DustDissolveScope(dust) {
            Text("Swipe me away")
                .padding()
                .dustSource(dust)
                .onTapGesture { dust.fire() }
        }
    }
}

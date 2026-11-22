import DustDissolve

struct Checkout: View {
    @StateObject private var dust = DustDissolveController()

    var body: some View {
        DustDissolveScope(dust) {                       // draws the dust over its content
            VStack {
                CouponTicket()
                    .dustSource(dust)                   // the coupon
                    .onTapGesture { dust.fire() }

                Spacer()

                TotalRow()
                    .background { Color.clear.frame(width: 58, height: 19).dustTarget() }   // where it lands
            }
        }
    }
}

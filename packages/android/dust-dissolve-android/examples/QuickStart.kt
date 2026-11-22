import com.repgem.dustdissolve.*

@Composable
fun Checkout() {
    val dust = remember { DustDissolveController() }

    DustDissolveScope(dust) {                               // draws the dust over its content
        Column {
            CouponTicket(
                Modifier
                    .dustSource(dust)                       // the coupon
                    .clickable { dust.fire() }
            )

            Spacer(Modifier.weight(1f))

            TotalRow(Modifier.dustTarget())                 // where it lands
        }
    }
}

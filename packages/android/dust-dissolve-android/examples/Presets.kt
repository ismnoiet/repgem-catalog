import com.repgem.dustdissolve.*

// Ready-made looks: Coupon, Snap, Dismiss, Fall, Burst. Tweak one with copy().
@Composable
fun DeleteRow() {
    val dust = remember {
        DustDissolveController(DustDissolveConfiguration.Fall.copy(particleCount = 700, seed = 3))
    }

    DustDissolveScope(dust) {
        Text("Swipe me away", Modifier.dustSource(dust).clickable { dust.fire() }.padding(16.dp))
    }
}

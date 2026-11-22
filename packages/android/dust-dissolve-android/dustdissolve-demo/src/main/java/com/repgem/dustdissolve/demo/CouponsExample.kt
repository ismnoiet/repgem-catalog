//
//  CouponsExample.kt
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
//  Two coupons. Tap one and it shimmers, then turns to dust and flows into the "Applied" pill. Each
//  coupon has its own controller, so they dissolve independently. The DustDissolve calls are
//  `Modifier.dustSource()` (the coupon), `Modifier.dustTarget()` (where the dust lands), `dust.fire()`
//  and the scope that draws the dust (in Examples.kt).
//
package com.repgem.dustdissolve.demo

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.defaultMinSize
import com.repgem.dustdissolve.dustTarget
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.PathOperation
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.repgem.dustdissolve.DustDissolveController
import com.repgem.dustdissolve.DustDissolveScope
import com.repgem.dustdissolve.dustSource

// MARK: - Theme

internal class Theme(
    val bg: Color, val fg: Color, val sub: Color, val card: Color, val line: Color, val onAccent: Color,
) {
    companion object {
        val Dark = Theme(Color.Black, Color.White, Color.White.copy(alpha = 0.6f), Color.White.copy(alpha = 0.05f),
            Color.White.copy(alpha = 0.12f), Color.Black)
        val Light = Theme(Color(0xFFF7F7F7), Color.Black, Color.Black.copy(alpha = 0.55f), Color.Black.copy(alpha = 0.03f),
            Color.Black.copy(alpha = 0.10f), Color.White)
    }
}

internal val Green = Color(0xFF40D173)

@Composable
internal fun Label(text: String, size: Float, weight: FontWeight, color: Color, modifier: Modifier = Modifier) {
    BasicText(text, modifier, style = TextStyle(fontSize = size.sp, fontWeight = weight, color = color))
}

// MARK: - Coupon ticket

private enum class Kind(val code: String, val pct: String, val colors: List<Color>) {
    M70("MOCHI70", "70%", listOf(
        Color(0xFFCCEDFF), Color(0xFFDBCCFF), Color(0xFFFFD9ED), Color(0xFFFFF2CC), Color(0xFFCCFFED), Color(0xFFD9E0FF))),
    M50("MOCHI50", "50%", listOf(Color(0xFFDBCCFF), Color(0xFFBDA8FF))),
}

/** The coupon. `scale` shrinks the whole thing (used for the mini coupon in the total row). */
@Composable
private fun Ticket(kind: Kind, modifier: Modifier = Modifier, scale: Float = 1f) {
    val w = 138f * scale
    val h = 44f * scale
    val notchX = 104f * scale
    val ink = Color.Black.copy(alpha = 0.88f)

    Box(modifier.requiredSize(w.dp, h.dp)) {
        Canvas(Modifier.size(w.dp, h.dp)) {
            val s = scale * density           // px per ticket unit
            val nx = notchX * density
            val body = Path().apply { addRoundRect(RoundRect(0f, 0f, size.width, size.height, CornerRadius(9f * s))) }
            val cut = Path().apply {
                addOval(Rect(Offset(nx, 0f), 4f * s))
                addOval(Rect(Offset(nx, size.height), 4f * s))
            }
            drawPath(
                Path.combine(PathOperation.Difference, body, cut),
                Brush.linearGradient(kind.colors, start = Offset.Zero, end = Offset(size.width, size.height)),
            )
            drawLine(
                Color.Black.copy(alpha = 0.18f), Offset(nx, 6f * s), Offset(nx, 38f * s), strokeWidth = s,
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(2f * s, 3f * s)),
            )
        }
        Row(Modifier.size(w.dp, h.dp).padding(start = (9f * scale).dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Label("mochi", 5f * scale, FontWeight.SemiBold, ink)
                Label(kind.code, 14f * scale, FontWeight.Bold, ink)
            }
            Box(Modifier.width((34f * scale).dp), contentAlignment = Alignment.Center) {
                Label(kind.pct, 13f * scale, FontWeight.SemiBold, ink)
            }
        }
    }
}

// MARK: - Card

@Composable
internal fun CouponsCard(dusts: List<DustDissolveController>, th: Theme) {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(26.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Coupon(Kind.M70, dusts[0])
            Coupon(Kind.M50, dusts[1])
        }

        // ← where the dust lands: the dots of both coupons flow into this pill
        val landed = dusts.count { it.time >= it.configuration.arrival }
        Row(
            Modifier
                .dustTarget()
                .background(th.fg.copy(alpha = 0.08f), CircleShape)
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Label("Applied", 13f, FontWeight.Medium, th.fg)
            Box(
                Modifier.defaultMinSize(minWidth = 22.dp, minHeight = 22.dp).background(th.fg.copy(alpha = 0.14f), CircleShape),
                contentAlignment = Alignment.Center,
            ) { Label("$landed", 13f, FontWeight.SemiBold, th.fg) }
        }
    }
}

@Composable
private fun Coupon(kind: Kind, dust: DustDissolveController) {
    Ticket(
        kind,
        Modifier
            .dustSource(dust)                                    // ← the coupon
            .pointerInput(dust) {
                // ignore taps while a coupon is mid-dissolve
                detectTapGestures { if (dust.time < 0 || dust.time > dust.configuration.total) dust.fire() }
            },
    )
}

@Preview(widthDp = 390, heightDp = 200)
@Composable
private fun CouponsPreview() {
    val dusts = remember { List(2) { DustDissolveController() } }
    DustDissolveScope(dusts) { CouponsCard(dusts, Theme.Dark) }
}

package com.repgem.tripsplash

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.max
import kotlin.math.pow

/**
 * Trip.com splash: the logo's letters get swallowed by the orange dot, the dot stretches into a streak
 * that shoots right, and your screen is revealed by an expanding circle. Tap to replay.
 *
 * Time is in seconds; positions are fractions of the screen width.
 * Draw-only state reads (graphicsLayer / Canvas) keep it smooth: nothing recomposes per frame.
 */
// ---------------------------------------------------------------------------------------------
// Palette and keyframes

private val SplashBlue = Color(0xFF2332F3)
private val HeaderBlue = Color(0xFF2B4DF3)
private val TripOrange = Color(0xFFFFB300)
private val TintBlue = Color(0xFFEDF2FF)

private fun keys(vararg pairs: Pair<Float, Float>): List<Pair<Float, Float>> = pairs.toList()

/** Piecewise-linear interpolation, clamped at both ends. */
private fun track(t: Float, k: List<Pair<Float, Float>>): Float {
    if (t <= k.first().first) return k.first().second
    if (t >= k.last().first) return k.last().second
    for (i in 1 until k.size) {
        val a = k[i - 1]
        val b = k[i]
        if (t <= b.first) return a.second + (b.second - a.second) * ((t - a.first) / (b.first - a.first))
    }
    return k.last().second
}

private object Splash {
    const val LOGO_END = 0.80f
    const val TOTAL = 1.4f

    val DOT = keys(
        0f to 0.0173f, 0.5f to 0.0173f, 0.55f to 0.0312f, 0.6f to 0.0341f, 0.683f to 0.0341f, 0.7f to 0.0312f, 0.717f to 0.0282f, 0.733f to 0.0134f, 0.8f to 0.0134f
    )
    val HEAD = keys(
        0.8f to 0.506f, 0.819f to 0.509f, 0.829f to 0.513f, 0.847f to 0.533f, 0.856f to 0.564f, 0.875f to 0.564f, 0.884f to 0.583f, 0.894f to 0.583f, 0.903f to 0.626f, 0.912f to 0.651f, 0.931f to 0.705f, 0.95f to 0.734f, 0.969f to 0.764f, 0.979f to 0.794f, 0.997f to 0.826f, 1.015f to 0.929f, 1.032f to 0.997f, 1.07f to 1.08f, 1.13f to 1.12f, 1.2f to 1.2f, 1.26f to 1.6f
    )
    val TAIL = keys(
        0.8f to 0.493f, 0.811f to 0.43f, 0.829f to 0.329f, 0.866f to 0.28f, 0.912f to 0.27f, 1.13f to 0.27f, 1.17f to 0.35f, 1.21f to 0.6f, 1.26f to 1f
    )
    val STREAK_OPACITY = keys(
        1.02f to 1f, 1.12f to 0.9f, 1.18f to 0.55f, 1.23f to 0.15f, 1.27f to 0f
    )

    const val BASELINE_BELOW_DOT = 0.0067f

    /**
     * How far a letter sits to the right of its measured track while it is full size (reference px).
     * It fades out with the letter's scale, so the letters still end exactly on the dot.
     * Matches the logo's resting spacing: the dot sits evenly between the "p" and the "c".
     */
    fun restShift(glyph: String): Float = when (glyph) {
        "T" -> 1f
        "r" -> 2f
        "m" -> 3.3f
        else -> 3f
    }

    /** Per letter: glyph, height of its centre above the baseline (screen widths), and a track of (t, centre x in reference px of a 674px frame, scale). */
    class LetterTrack(val glyph: String, val above: Float, val keys: List<Triple<Float, Float, Float>>)
    const val DOT_X = 336.5f
    const val REF_WIDTH = 674f
    val LETTER_TRACKS = listOf(
        LetterTrack("T", 0.0356f, listOf(Triple(0.5f, 224.5f, 1f), Triple(0.55f, 222.5f, 1f), Triple(0.6f, 219f, 0.97f), Triple(0.617f, 217f, 0.97f), Triple(0.65f, 215f, 0.97f), Triple(0.667f, 215f, 0.97f), Triple(0.683f, 222f, 0.93f), Triple(0.7f, 237f, 0.85f), Triple(0.717f, 245f, 0.78f), Triple(0.733f, 298f, 0.43f), Triple(0.75f, 314f, 0.38f), Triple(0.767f, 322.5f, 0.3f), Triple(0.783f, 329.5f, 0.22f), Triple(0.8f, 336.5f, 0f))),
        LetterTrack("r", 0.0356f, listOf(Triple(0.5f, 252f, 1f), Triple(0.55f, 250.5f, 1f), Triple(0.6f, 250f, 1f), Triple(0.617f, 251.5f, 1f), Triple(0.633f, 255.5f, 1f), Triple(0.65f, 264.5f, 0.95f), Triple(0.667f, 264.5f, 0.95f), Triple(0.683f, 269f, 0.89f), Triple(0.7f, 278f, 0.79f), Triple(0.717f, 282.5f, 0.74f), Triple(0.733f, 314f, 0.45f), Triple(0.75f, 316f, 0.38f), Triple(0.767f, 322.5f, 0.3f), Triple(0.783f, 329.5f, 0.22f), Triple(0.8f, 336.5f, 0f))),
        LetterTrack("i", 0.0371f, listOf(Triple(0.5f, 272f, 1f), Triple(0.55f, 269.5f, 1f), Triple(0.567f, 268.5f, 0.95f), Triple(0.583f, 275.5f, 0.9f), Triple(0.6f, 279f, 0.95f), Triple(0.617f, 285.5f, 0.9f), Triple(0.633f, 289f, 0.85f), Triple(0.65f, 295.5f, 0.73f), Triple(0.667f, 295.5f, 0.73f), Triple(0.683f, 299f, 0.64f), Triple(0.7f, 305.5f, 0.55f), Triple(0.717f, 309.5f, 0.55f), Triple(0.733f, 336.5f, 0f))),
        LetterTrack("p", 0.0141f, listOf(Triple(0.5f, 303.5f, 1f), Triple(0.55f, 303f, 1f), Triple(0.567f, 306.5f, 0.94f), Triple(0.583f, 310.5f, 0.83f), Triple(0.6f, 315.5f, 0.8f), Triple(0.617f, 316f, 0.69f), Triple(0.633f, 317.5f, 0.67f), Triple(0.65f, 322.5f, 0.61f), Triple(0.667f, 322.5f, 0.61f), Triple(0.683f, 323.5f, 0.56f), Triple(0.7f, 329f, 0.53f), Triple(0.717f, 327f, 0.25f), Triple(0.733f, 336.5f, 0f))),
        LetterTrack("c", 0.0252f, listOf(Triple(0.5f, 359.5f, 1f), Triple(0.55f, 367.5f, 1f), Triple(0.567f, 364.5f, 1f), Triple(0.583f, 361f, 0.89f), Triple(0.6f, 359.5f, 0.86f), Triple(0.617f, 356.5f, 0.79f), Triple(0.633f, 355f, 0.75f), Triple(0.65f, 352f, 0.61f), Triple(0.667f, 352f, 0.61f), Triple(0.683f, 350.5f, 0.57f), Triple(0.7f, 348f, 0.46f), Triple(0.717f, 347f, 0.39f), Triple(0.733f, 336.5f, 0f))),
        LetterTrack("o", 0.0252f, listOf(Triple(0.5f, 394.5f, 1f), Triple(0.55f, 401.5f, 1f), Triple(0.583f, 402.5f, 1f), Triple(0.6f, 402.5f, 1f), Triple(0.617f, 398.5f, 0.94f), Triple(0.633f, 394.5f, 0.89f), Triple(0.65f, 386f, 0.85f), Triple(0.667f, 386f, 0.85f), Triple(0.683f, 382f, 0.79f), Triple(0.7f, 374f, 0.68f), Triple(0.717f, 369.5f, 0.65f), Triple(0.733f, 336.5f, 0f))),
        LetterTrack("m", 0.0252f, listOf(Triple(0.5f, 443f, 1f), Triple(0.55f, 450f, 1f), Triple(0.6f, 452f, 1f), Triple(0.65f, 453f, 1f), Triple(0.667f, 453f, 1f), Triple(0.683f, 446f, 0.96f), Triple(0.7f, 431.5f, 0.86f), Triple(0.717f, 424f, 0.8f), Triple(0.733f, 373f, 0.45f), Triple(0.75f, 358.5f, 0.35f), Triple(0.767f, 351f, 0.29f), Triple(0.783f, 345f, 0.22f), Triple(0.8f, 336.5f, 0f))),
    )
}

/** Centre x (reference px) and scale of one letter at time t. */
private fun letterState(k: List<Triple<Float, Float, Float>>, t: Float): Pair<Float, Float> {
    if (t <= k.first().first) return k.first().second to k.first().third
    if (t >= k.last().first) return k.last().second to k.last().third
    for (i in 1 until k.size) {
        val a = k[i - 1]
        val b = k[i]
        if (t <= b.first) {
            val u = (t - a.first) / (b.first - a.first)
            return (a.second + (b.second - a.second) * u) to (a.third + (b.third - a.third) * u)
        }
    }
    return k.last().second to k.last().third
}

/**
 * One smooth curve (no keyframe kinks): starts fast and eases out, like the original.
 * Returns how far the circle's middle has travelled, in screen widths; it reaches the
 * right edge (1.0) after ~0.175s and the corners are covered at 1.6.
 */
private fun revealEdge(t: Float): Float {
    val u = ((t - 1.0f) / 0.322f).coerceIn(0f, 1f)
    return 1.6f * (1f - (1f - u).pow(1.25f))
}

private class RevealShape(val cx: Float, val cy: Float, val r: Float) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(Path().apply { addOval(Rect(Offset(cx, cy), r)) })
}

// ---------------------------------------------------------------------------------------------
// Scene

/**
 * The splash. [content] is the screen it reveals; the default is a neutral placeholder.
 * Use it as `TripSplash { YourHomeScreen() }`.
 */
@Composable
fun TripSplash(modifier: Modifier = Modifier, content: @Composable () -> Unit = { TripSplashPlaceholder() }) {
    val clock = remember { mutableFloatStateOf(0f) }
    var run by remember { mutableIntStateOf(0) }

    LaunchedEffect(run) {
        clock.floatValue = 0f
        val start = androidx.compose.runtime.withFrameNanos { it }
        while (clock.floatValue < Splash.TOTAL) {
            val now = androidx.compose.runtime.withFrameNanos { it }
            clock.floatValue = ((now - start) / 1_000_000_000f).coerceAtMost(Splash.TOTAL)
        }
    }

    val measurer = rememberTextMeasurer()

    Box(
        modifier
            .fillMaxSize()
            .background(SplashBlue)
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { run++ }
    ) {
        // Layer 1: your screen. Rendered once; only the circular clip changes per frame.
        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer {
                    // Strongly curved circle: the radius barely grows while its centre slides right.
                    val edge = revealEdge(clock.floatValue)
                    val radius = size.width * (1.29f + 0.16f * edge)
                    clip = true
                    shape = RevealShape(size.width * edge - radius, size.height / 2f, radius)
                }
        ) { content() }

        // Layers 2 and 3: logo -> dot, then the streak
        Canvas(Modifier.fillMaxSize()) {
            val t = clock.floatValue
            val w = size.width
            val dotY = size.height / 2f + w * 0.0163f

            if (t < Splash.LOGO_END) {
                val unit = w / Splash.REF_WIDTH
                val dotXpx = w * Splash.DOT_X / Splash.REF_WIDTH
                val style = TextStyle(color = Color.White, fontSize = (w * 0.101f).toSp(), fontWeight = FontWeight.Bold)
                for (letter in Splash.LETTER_TRACKS) {
                    val (x, s) = letterState(letter.keys, t)
                    if (s < 0.01f) continue
                    val restX = letter.keys.first().second
                    val g = ((x - Splash.DOT_X) / (restX - Splash.DOT_X)).coerceIn(0f, 1f)
                    val layout = measurer.measure(letter.glyph, style)
                    val above = letter.above * w
                    val cx = dotXpx + (x + Splash.restShift(letter.glyph) * s - Splash.DOT_X) * unit
                    val cy = dotY + (Splash.BASELINE_BELOW_DOT - letter.above) * w * g
                    withTransform({
                        translate(cx, cy)
                        scale(s * 0.92f, s, pivot = Offset.Zero)
                    }) {
                        drawText(layout, topLeft = Offset(-layout.size.width / 2f, above - layout.firstBaseline))
                    }
                }
                // The dot is drawn last so it covers the letters entering it.
                drawCircle(TripOrange, radius = track(t, Splash.DOT) * w / 2f, center = Offset(dotXpx, dotY))
            }

            if (t >= Splash.LOGO_END && t < 1.27f) {
                val head = w * track(t, Splash.HEAD)
                val tail = w * track(t, Splash.TAIL)
                val length = max(head - tail, w * 0.0134f)
                val thickness = w * 0.0148f
                val fade = if (t < 1.018f) 1f else track(t, Splash.STREAK_OPACITY)
                val a = (1f - length / (w * 0.18f)).coerceIn(0f, 1f)
                val brush = Brush.horizontalGradient(
                    0f to TripOrange.copy(alpha = a),
                    0.5f to TripOrange.copy(alpha = a + (1f - a) * 0.35f),
                    0.8f to TripOrange.copy(alpha = a + (1f - a) * 0.75f),
                    1f to TripOrange,
                    startX = tail,
                    endX = tail + length,
                )
                drawRoundRect(
                    brush = brush,
                    topLeft = Offset(tail, dotY - thickness / 2f),
                    size = Size(length, thickness),
                    cornerRadius = CornerRadius(thickness / 2f),
                    alpha = fade,
                )
            }
        }

    }
}

// ---------------------------------------------------------------------------------------------
// Placeholder destination: just enough structure to judge the sweep

@Composable
fun TripSplashPlaceholder() {
    Column(Modifier.fillMaxSize().background(HeaderBlue)) {
        Box(Modifier.fillMaxWidth().height(72.dp))
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                .background(Color.White)
                .padding(horizontal = 16.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                repeat(4) { Box(Modifier.size(52.dp).clip(CircleShape).background(TintBlue)) }
            }
            Box(Modifier.fillMaxWidth().height(36.dp).clip(RoundedCornerShape(50)).background(TintBlue))
            Box(Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(12.dp)).background(TintBlue))
            Box(Modifier.fillMaxWidth().height(96.dp).clip(RoundedCornerShape(12.dp)).background(TintBlue))
        }
    }
}

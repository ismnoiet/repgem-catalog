//
//  StickyMath.kt
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Pure geometry and value math, kept free of Compose state so it can be unit-tested.
//  All lengths are in dp, so the slider looks the same on every density.
//
package com.repgem.stickyrangeslider

import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Sizes measured from the reference interaction (dp). Same numbers as the iOS package. */
internal object StickyMetrics {
    const val PILL_HEIGHT = 26f
    const val PILL_RADIUS = 11f
    const val PILL_PAD = 10f
    const val FONT_SIZE = 12f              // sp
    const val DASH_WIDTH = 14f             // " – " between the two merged values
    const val DASH_GLYPH = 6f
    const val TRACK_HEIGHT = 2f
    const val INSET = 30f                  // room so the end pills don't clip
    const val HEIGHT = 72f

    /**
     * Centre distance at which two pills fuse, and at which they release. The gap between the
     * two is the hysteresis that stops the pair flickering while you hover around the threshold.
     */
    const val MERGE_BELOW = 48f
    const val SPLIT_ABOVE = 58f

    const val GOO_BLUR = 4.5f
    const val SHADOW_BLUR = 5f
    const val TAP_SLOP = 6f                // extra grab area around a pill
    const val DRAG_START = 6f              // travel before a tap becomes a drag
}

internal object StickyMath {

    // Values <-> positions

    /** x position (including the leading inset) of a value on a track [width] wide. */
    fun x(value: Double, width: Float, bounds: IntRange): Float {
        val lo = bounds.first.toDouble()
        val hi = bounds.last.toDouble()
        if (hi <= lo) return StickyMetrics.INSET
        return StickyMetrics.INSET + ((value - lo) / (hi - lo)).toFloat() * width
    }

    /** The (unsnapped) value under an x position, clamped to the bounds. */
    fun value(x: Float, width: Float, bounds: IntRange): Double {
        val lo = bounds.first.toDouble()
        val hi = bounds.last.toDouble()
        val raw = lo + ((x - StickyMetrics.INSET) / max(width, 1f)).toDouble() * (hi - lo)
        return min(max(raw, lo), hi)
    }

    /** Rounds to the nearest [step] and clamps to the bounds. */
    fun snap(value: Double, step: Int, bounds: IntRange): Int {
        val s = max(step, 1)
        val n = (value / s).roundToInt() * s
        return min(max(n, bounds.first), bounds.last)
    }

    // Merging

    /** Fuse when the pills get close, release only once they are clearly apart. */
    fun merged(current: Boolean, distance: Float): Boolean = when {
        !current && distance < StickyMetrics.MERGE_BELOW -> true
        current && distance > StickyMetrics.SPLIT_ABOVE -> false
        else -> current
    }

    // Text

    /** Width estimate for the 12sp label font (digits are tabular). Avoids measuring text. */
    fun textWidth(s: String): Float {
        var total = 0f
        for (c in s) {
            total += when {
                c.isDigit() -> 7.2f
                c == ' ' -> 3.3f
                c == '.' || c == ',' || c == '\'' -> 3.4f
                c.isUpperCase() -> 7.9f
                c.isLowerCase() -> 6.4f
                else -> 7.2f                   // currency signs and the like
            }
        }
        return total
    }

    fun pillWidth(text: String): Float = textWidth(text) + 2 * StickyMetrics.PILL_PAD

    fun mergedWidth(lower: String, upper: String): Float =
        textWidth(lower) + textWidth(upper) + StickyMetrics.DASH_WIDTH + 2 * StickyMetrics.PILL_PAD

    // Springs

    /** Angular frequency for a spring that takes about [response] seconds to catch up. */
    fun omega(response: Double): Float = (2.0 * Math.PI / max(response, 0.05)).toFloat()

    fun lerp(a: Float, b: Float, t: Float): Float = a + (b - a) * t
    fun clamp01(v: Float): Float = min(max(v, 0f), 1f)
}

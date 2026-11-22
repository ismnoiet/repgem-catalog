//
//  DustDissolveConfiguration.kt
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
package com.repgem.dustdissolve

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Which way the view is eaten away. The dust is born in the same order. */
enum class DustDissolveDirection {
    LeftToRight, RightToLeft, TopToBottom, BottomToTop,

    /** From the centre outwards (pairs well with [DustDissolveMotion.Burst] and [DustDissolveShape.Ellipse]). */
    CenterOut,
}

/** Where the dust goes once it has left the view. */
sealed interface DustDissolveMotion {
    /**
     * Streams along an arc to the element marked with `Modifier.dustTarget()`
     * (falls back to a small burst when there is no target).
     */
    object FlowToTarget : DustDissolveMotion

    /** Blows away in one direction. `angleDegrees`: 0° = right, 90° = down, −90° = up. */
    data class Drift(val angleDegrees: Float, val distance: Dp) : DustDissolveMotion

    /** Flies outward from the centre of the view. */
    data class Burst(val distance: Dp) : DustDissolveMotion
}

/** Where dust may be born. Use [Ellipse] for round views so no dots appear in the empty corners. */
enum class DustDissolveShape { Rectangle, Ellipse }

/**
 * Timing and look of one dust-dissolve run. All times are seconds since `fire()`.
 *
 * The defaults are matched frame by frame to the original 3-second coupon recording:
 *
 *     0.28 – 0.62   shimmer line crosses the coupon
 *     0.55 – 1.10   coupon dissolves left → right, dust is born where it is eaten away
 *     0.95 – 2.10   the cloud collapses and streams along an arc to the target
 *     3.00          end of the sequence (host UI can use the whole range through `controller.time`)
 *
 * Presets for other behaviors: [Snap], [Dismiss], [Fall], [Burst].
 */
data class DustDissolveConfiguration(
    /** A light line crosses the view before it dissolves. */
    val shimmer: Boolean = true,
    val shimmerStart: Double = 0.28,
    val shimmerEnd: Double = 0.62,

    val direction: DustDissolveDirection = DustDissolveDirection.LeftToRight,
    val motion: DustDissolveMotion = DustDissolveMotion.FlowToTarget,
    val shape: DustDissolveShape = DustDissolveShape.Rectangle,

    val dissolveStart: Double = 0.55,
    val dissolveEnd: Double = 1.10,
    val flightStart: Double = 0.95,
    /** Random extra delay (0…flightStagger) before each dot leaves the cloud. */
    val flightStagger: Double = 0.15,
    /** How long one dot takes to fly away (picked per dot from this range). */
    val flightDurationMin: Double = 0.8,
    val flightDurationMax: Double = 0.95,
    /** Length of the whole sequence. The clock stops (and the end state holds) after this. */
    val total: Double = 3.0,

    val particleCount: Int = 1100,
    /** Dot diameter range, in dp. */
    val dotSizeMin: Float = 1.8f,
    val dotSizeMax: Float = 3.2f,
    /** Every n-th dot flares into a 4-point sparkle. `0` turns sparkles off. */
    val sparkleEvery: Int = 60,
    /** Dot colors, picked at random per dot. */
    val palette: List<Color> = DustDissolvePalette.Pastel,
    val seed: Long = 7,
) {
    /** When the first dots are gone / reach the target (a good moment to pop the "landed" UI). */
    val arrival: Double get() = flightStart + flightDurationMin

    companion object {
        /** The original coupon: shimmer, dissolve left → right, dust flows to a target. */
        val Coupon = DustDissolveConfiguration()

        /** "Thanos snap": no shimmer, dissolves left → right, the dust blows away up and to the right. */
        val Snap = DustDissolveConfiguration(
            shimmer = false,
            motion = DustDissolveMotion.Drift(-28f, 150.dp),
            dissolveStart = 0.05, dissolveEnd = 0.85,
            flightStart = 0.40, flightStagger = 0.45, flightDurationMin = 1.0, flightDurationMax = 1.5,
            total = 2.4,
        )

        /** Dismiss a card: dissolves left → right, the dust is carried off to the right. */
        val Dismiss = DustDissolveConfiguration(
            shimmer = false,
            motion = DustDissolveMotion.Drift(-12f, 230.dp),
            dissolveStart = 0.05, dissolveEnd = 0.75,
            flightStart = 0.35, flightStagger = 0.35, flightDurationMin = 0.9, flightDurationMax = 1.3,
            total = 2.2,
        )

        /** Delete a row: dissolves top → bottom and the dust falls. */
        val Fall = DustDissolveConfiguration(
            shimmer = false,
            direction = DustDissolveDirection.TopToBottom,
            motion = DustDissolveMotion.Drift(90f, 110.dp),
            dissolveStart = 0.05, dissolveEnd = 0.70,
            flightStart = 0.30, flightStagger = 0.35, flightDurationMin = 0.8, flightDurationMax = 1.2,
            total = 2.0,
        )

        /** Round avatar or badge: dissolves from the centre out, the dust bursts outward. */
        val Burst = DustDissolveConfiguration(
            shimmer = false,
            direction = DustDissolveDirection.CenterOut,
            shape = DustDissolveShape.Ellipse,
            motion = DustDissolveMotion.Burst(120.dp),
            dissolveStart = 0.05, dissolveEnd = 0.70,
            flightStart = 0.30, flightStagger = 0.30, flightDurationMin = 0.9, flightDurationMax = 1.3,
            total = 2.1,
        )
    }
}

object DustDissolvePalette {
    /** Lavender, pink, ice blue and white: reads well on dark and light backgrounds. */
    val Pastel: List<Color> = listOf(
        Color(0xFFD6C2FF),
        Color(0xFFEDCCFF),
        Color(0xFFFFD1ED),
        Color(0xFFC2E6FF),
        Color(0xFFBDFFF2),
        Color.White,
    )
}

// MARK: - Small math helpers shared by the library

internal fun ramp(t: Double, a: Double, b: Double): Double = ((t - a) / (b - a)).coerceIn(0.0, 1.0)
internal fun smooth(x: Double): Double = x * x * (3 - 2 * x)
internal fun easeOut(x: Double): Double = 1 - Math.pow(1 - x, 3.0)

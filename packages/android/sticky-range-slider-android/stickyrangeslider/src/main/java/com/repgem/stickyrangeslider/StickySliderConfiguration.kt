//
//  StickySliderConfiguration.kt
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
package com.repgem.stickyrangeslider

import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color

/**
 * Colors of the slider. Use a preset or build your own.
 *
 *     StickyRangeSlider(..., style = StickySliderStyle.ink)             // dark pill, for light surfaces (default)
 *     StickyRangeSlider(..., style = StickySliderStyle.paper)           // light pill, for dark surfaces
 *     StickyRangeSlider(..., style = StickySliderStyle.accent(Color.Blue))
 *
 * Same names as the iOS `StickySliderStyle`.
 *
 * @param pill fill of the pills (and of the neck that joins them)
 * @param label text color inside the pills
 * @param track the full track
 * @param trackFill the part of the track between the handles
 * @param shadow drop shadow under the pills
 */
@Immutable
data class StickySliderStyle(
    val pill: Color,
    val label: Color,
    val track: Color,
    val trackFill: Color,
    val shadow: Color = Color.Black.copy(alpha = 0.16f),
) {
    companion object {
        /** Near-black pills and track, for light surfaces. */
        val ink = StickySliderStyle(
            pill = Color(0.11f, 0.11f, 0.11f),
            label = Color.White,
            track = Color(0.89f, 0.89f, 0.89f),
            trackFill = Color(0.11f, 0.11f, 0.11f),
        )

        /** Near-white pills and track, for dark surfaces. */
        val paper = StickySliderStyle(
            pill = Color(0.96f, 0.96f, 0.96f),
            label = Color(0.10f, 0.10f, 0.10f),
            track = Color.White.copy(alpha = 0.16f),
            trackFill = Color(0.96f, 0.96f, 0.96f),
            shadow = Color.Black.copy(alpha = 0.45f),
        )

        /** A colored pill with white text; the track follows the color. */
        fun accent(color: Color) = StickySliderStyle(
            pill = color,
            label = Color.White,
            track = color.copy(alpha = 0.18f),
            trackFill = color,
            shadow = color.copy(alpha = 0.35f),
        )
    }
}

/**
 * How the slider moves. Every value is a spring *response* in seconds: roughly how long the
 * element takes to catch up. Smaller is snappier.
 *
 * @param follow a pill chasing your finger while you drag
 * @param glide a pill sliding to a spot you tapped on the track
 * @param merge two pills fusing into one, or splitting apart
 * @param digitRoll digits rolling when the value changes
 */
@Immutable
data class StickyTiming(
    val follow: Double = 0.22,
    val glide: Double = 0.37,
    val merge: Double = 0.26,
    val digitRoll: Double = 0.28,
) {
    companion object {
        val default = StickyTiming()
    }
}

/** Spring damping used for the three motions. Slightly under 1 so pills settle with a tiny give. */
internal object StickyDamping {
    const val FOLLOW = 0.82f
    const val GLIDE = 0.9f
    const val MERGE = 0.9f
}

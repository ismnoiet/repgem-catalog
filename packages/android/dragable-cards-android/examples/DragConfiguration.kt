//
//  DragConfiguration.kt
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Everything you can tune on a DragBoard: timing (springs, long press), the look of the lifted
//  card, and the column chrome. All of it has sensible defaults.
//
package com.repgem.dragablecards

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** A spring described by its damping ratio (1 = no overshoot) and stiffness. */
@Immutable
data class DragSpring(val dampingRatio: Float, val stiffness: Float)

/** Durations and springs of the interaction. */
@Immutable
data class DragTiming(
    /** How long to hold a card before it lifts, in milliseconds. */
    val longPressMillis: Long = 150L,
    /** The lift: scale, tilt and shadow ease in with this spring. */
    val lift: DragSpring = DragSpring(dampingRatio = 0.72f, stiffness = 990f),
    /** Neighbouring cards sliding out of the way when the slot changes. */
    val shuffle: DragSpring = DragSpring(dampingRatio = 0.86f, stiffness = 815f),
    /** The release: near critically damped so the card snaps into its slot without wobble. */
    val drop: DragSpring = DragSpring(dampingRatio = 1f, stiffness = 600f),
    /** Minimum gap between two automatic horizontal scrolls near the screen edge. */
    val edgeScrollDelayMillis: Long = 700L,
)

/** How the lifted card and the empty slot look. */
@Immutable
data class DragAppearance(
    val liftScale: Float = 1.04f,
    /** Tilt of the lifted card, in degrees. */
    val liftTilt: Float = 4f,
    val liftShadow: Dp = 12.dp,
    /** Corner radius used to cast the shadow; match your card's shape. */
    val cornerRadius: Dp = 6.dp,
    val placeholderFill: Color = Color(0xFFE6EAEF),
    val placeholderBorder: Color = Color(0xFFD0D7DE),
)

/** The container drawn around each column's header and cards. */
@Immutable
data class ColumnStyle(
    val background: Color = Color(0xFFF6F8FA),
    val border: Color = Color(0xFFD0D7DE),
    val shape: Shape = RoundedCornerShape(10.dp),
    val padding: PaddingValues = PaddingValues(12.dp),
)

//
//  Placement.kt
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Two small layout modifiers: one animates a child when its layout position changes (cards
//  sliding out of the way), the other lets a card keep its state while taking no space.
//
package com.repgem.dragablecards

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.animation.core.AnimationVector2D
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.round
import kotlinx.coroutines.launch

private class PlacementHolder {
    var target by mutableStateOf(IntOffset.Zero)
    var anim: Animatable<IntOffset, AnimationVector2D>? = null
}

/**
 * Animates this node from its previous layout position to its new one. [onPlaced] receives the
 * node's coordinates *before* the animation offset, i.e. the logical slot, which is what the
 * hit-testing needs (it doesn't jitter while neighbours are still moving).
 */
internal fun Modifier.animatePlacement(
    spec: DragSpring,
    onPlaced: (LayoutCoordinates) -> Unit,
): Modifier = composed {
    val scope = rememberCoroutineScope()
    val holder = remember { PlacementHolder() }
    this
        .onPlaced { coords ->
            onPlaced(coords)
            val next = coords.positionInParent().round()
            if (holder.anim == null) {
                // First placement: appear in place, don't fly in from the origin.
                holder.anim = Animatable(next, IntOffset.VectorConverter)
            }
            holder.target = next
        }
        .offset {
            val anim = holder.anim
            if (anim == null) {
                IntOffset.Zero
            } else {
                val target = holder.target
                if (anim.targetValue != target) {
                    scope.launch {
                        anim.animateTo(
                            target,
                            spring(spec.dampingRatio, spec.stiffness, IntOffset.VisibilityThreshold),
                        )
                    }
                }
                anim.value - target
            }
        }
}

/** Measures the content (so its state survives) but reports zero height and draws nothing. */
internal fun Modifier.collapsed(collapsed: Boolean): Modifier = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints)
    if (collapsed) {
        layout(placeable.width, 0) {}
    } else {
        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
    }
}

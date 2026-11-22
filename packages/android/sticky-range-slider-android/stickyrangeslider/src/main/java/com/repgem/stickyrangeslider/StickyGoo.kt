//
//  StickyGoo.kt
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
//  The "goo" trick: blur the pills, then push the alpha channel to a hard edge. Shapes that are
//  close blur into each other and the threshold turns the overlap back into one crisp outline.
//  Needs RenderEffect (API 31). Below that, the pills are drawn plain and simply overlap.
//
package com.repgem.stickyrangeslider

import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.RenderEffect
import android.graphics.Shader
import androidx.annotation.RequiresApi
import androidx.compose.ui.graphics.asComposeRenderEffect

/** Blur, then alpha threshold at 0.5 (gain 20, offset -10 in 0..255 units). */
@RequiresApi(31)
internal fun gooRenderEffect(blurPx: Float): androidx.compose.ui.graphics.RenderEffect {
    val blur = RenderEffect.createBlurEffect(blurPx, blurPx, Shader.TileMode.DECAL)
    val threshold = ColorMatrix(
        floatArrayOf(
            1f, 0f, 0f, 0f, 0f,
            0f, 1f, 0f, 0f, 0f,
            0f, 0f, 1f, 0f, 0f,
            0f, 0f, 0f, 20f, -2550f,
        ),
    )
    return RenderEffect
        .createColorFilterEffect(ColorMatrixColorFilter(threshold), blur)
        .asComposeRenderEffect()
}

/** A soft blur, used for the drop shadow under the fused shape. */
@RequiresApi(31)
internal fun softShadowRenderEffect(blurPx: Float): androidx.compose.ui.graphics.RenderEffect =
    RenderEffect.createBlurEffect(blurPx, blurPx, Shader.TileMode.DECAL).asComposeRenderEffect()

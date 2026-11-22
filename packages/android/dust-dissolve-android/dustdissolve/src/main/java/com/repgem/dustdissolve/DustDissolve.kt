//
//  DustDissolve.kt
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
//  Three pieces:
//
//    DustDissolveScope(dust) { … }        a container that draws the dust on top of its content
//    Modifier.dustSource(dust)    the view that dissolves; the dust is born where it erodes
//    Modifier.dustTarget()        optional: where the dust flows to (the total, a cart badge…)
//
//  One scope can run many sources at once (a grid, the rows of a list): give each its own
//  controller and pass them all to the scope. The source keeps its place in the layout, so
//  nothing around it moves.
//
//  Positions are compared in window space and only their *difference* is used, so the dust always
//  lands in the right place whatever offset the scope has (status bar, insets, scrolling).
//
package com.repgem.dustdissolve

import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.platform.LocalContext

/** True when the user turned animations off (the Android equivalent of Reduce Motion). */
private fun isReduceMotionEnabled(context: Context): Boolean =
    Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f

// MARK: - Registry (source / target frames, shared through the scope)

internal class DustRegistry {
    var origin by mutableStateOf(Offset.Zero)
    val sources = mutableStateMapOf<DustDissolveController, Rect>()

    /** `null` key = the shared target that every controller without its own target flows to. */
    val targets = mutableStateMapOf<DustDissolveController?, Rect>()
    var reduceMotion = false
    var shaderErosion = false
}

internal val LocalDustRegistry = compositionLocalOf<DustRegistry?> { null }

// MARK: - Scope

/**
 * Wrap the screen (or the area the dust may fly across). It draws the dust over its content,
 * never takes touches, and runs the frame clock while a run is active.
 *
 *     DustDissolveScope(dust) {
 *         Column {
 *             Ticket(Modifier.dustSource(dust))
 *             …
 *             TotalRow(Modifier.dustTarget())
 *         }
 *     }
 */
@Composable
fun DustDissolveScope(
    controller: DustDissolveController,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) = DustDissolveScope(listOf(controller), modifier, content)

/** Several views at once: give each its own controller and pass them all here. */
@Composable
fun DustDissolveScope(
    controllers: List<DustDissolveController>,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    val context = LocalContext.current
    val reduceMotion = remember(context) { isReduceMotionEnabled(context) }
    val registry = remember { DustRegistry() }
    registry.reduceMotion = reduceMotion

    // One frame clock per controller: it only runs while that sequence is active.
    controllers.forEach { c -> key(c) { DustClock(c, reduceMotion) } }

    CompositionLocalProvider(LocalDustRegistry provides registry) {
        Box(modifier.onGloballyPositioned { registry.origin = it.positionInWindow() }) {
            content()
            Canvas(Modifier.matchParentSize()) {
                if (registry.reduceMotion) return@Canvas
                val o = registry.origin
                for (c in controllers) {
                    val t = c.time
                    val cfg = c.configuration
                    val s = registry.sources[c]
                    if (t <= cfg.dissolveStart || s == null) continue
                    val g = registry.targets[c] ?: registry.targets[null]
                    drawDust(
                        t = t,
                        c = s.translate(-o.x, -o.y),
                        g = g?.translate(-o.x, -o.y),
                        cfg = cfg,
                        particles = c.particles,
                        shaderErosion = registry.shaderErosion,
                    )
                }
            }
        }
    }
}

@Composable
private fun DustClock(controller: DustDissolveController, reduceMotion: Boolean) {
    LaunchedEffect(controller.runId) {
        if (!controller.isActive) return@LaunchedEffect
        if (reduceMotion) { controller.finish(); return@LaunchedEffect }
        val total = controller.configuration.total
        val t0 = withFrameNanos { it }
        while (true) {
            val t = withFrameNanos { (it - t0) / 1_000_000_000.0 }
            if (t >= total) break
            controller.time = t
        }
        controller.finish()
    }
}

// MARK: - Source

/**
 * Marks the view that dissolves (a coupon, a card, an avatar…). The dust is born where it is eaten
 * away, in the direction set by `configuration.direction`. Must sit inside a [DustDissolveScope] that
 * was given the same controller.
 *
 * Android 13+ uses an AGSL shader (dithered edge, optional shimmer). Older versions use a
 * straight-edged reveal and no shimmer; the dust is identical.
 */
fun Modifier.dustSource(controller: DustDissolveController): Modifier = composed {
    val registry = LocalDustRegistry.current
    val agsl = remember { if (Build.VERSION.SDK_INT >= 33) DustAgsl() else null }
    SideEffect { registry?.shaderErosion = agsl != null }
    DisposableEffect(controller, registry) { onDispose { registry?.sources?.remove(controller) } }
    val cfg = controller.configuration

    val base = this.onGloballyPositioned { registry?.sources?.set(controller, it.boundsInWindow()) }
    if (agsl != null) {
        base.graphicsLayer {
            val t = controller.time
            if (t < 0) {
                renderEffect = null
            } else {
                val dissolve = ramp(t, cfg.dissolveStart, cfg.dissolveEnd).toFloat()
                val shimmer = if (cfg.shimmer) ramp(t, cfg.shimmerStart, cfg.shimmerEnd).toFloat() else 0f
                renderEffect = if (dissolve > 0f || (shimmer > 0f && shimmer < 1f)) {
                    agsl.effect(size.width, size.height, density, dissolve, shimmer, cfg.direction.ordinal.toFloat())
                } else null
            }
        }
    } else {
        // centre-out has no straight edge, so it fades instead
        base
            .graphicsLayer {
                val t = controller.time
                alpha = if (cfg.direction == DustDissolveDirection.CenterOut && t >= 0) {
                    1f - ramp(t, cfg.dissolveStart, cfg.dissolveEnd).toFloat()
                } else 1f
            }
            .drawWithContent {
                val t = controller.time
                val p = if (t < 0) 0.0 else ramp(t, cfg.dissolveStart, cfg.dissolveEnd)
                if (p <= 0.0 || cfg.direction == DustDissolveDirection.CenterOut) {
                    drawContent()
                } else if (p < 1.0) {
                    val th = -0.06 + 1.2 * p
                    val f = ((th - 0.11) / 0.82).coerceIn(0.0, 1.0).toFloat()
                    val w = size.width
                    val h = size.height
                    when (cfg.direction) {
                        DustDissolveDirection.LeftToRight -> clipRect(f * w, 0f, w, h) { this@drawWithContent.drawContent() }
                        DustDissolveDirection.RightToLeft -> clipRect(0f, 0f, w - f * w, h) { this@drawWithContent.drawContent() }
                        DustDissolveDirection.TopToBottom -> clipRect(0f, f * h, w, h) { this@drawWithContent.drawContent() }
                        DustDissolveDirection.BottomToTop -> clipRect(0f, 0f, w, h - f * h) { this@drawWithContent.drawContent() }
                        DustDissolveDirection.CenterOut -> Unit
                    }
                }
            }
    }
}

// MARK: - Target

/**
 * Marks where the dust flows to (only used by `DustDissolveMotion.FlowToTarget`). The dots aim at the
 * centre of this element's bounds. Pass a controller to give that one its own target; with none,
 * every controller in the scope that has no target of its own flows here.
 */
fun Modifier.dustTarget(controller: DustDissolveController? = null): Modifier = composed {
    val registry = LocalDustRegistry.current
    DisposableEffect(controller, registry) { onDispose { registry?.targets?.remove(controller) } }
    this.onGloballyPositioned { registry?.targets?.set(controller, it.boundsInWindow()) }
}

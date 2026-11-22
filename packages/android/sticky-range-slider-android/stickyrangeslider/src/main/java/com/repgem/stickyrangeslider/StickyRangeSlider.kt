//
//  StickyRangeSlider.kt
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
package com.repgem.stickyrangeslider

import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * A slider whose handles are value pills that spring after your finger.
 *
 *  - Two handles that drift together fuse into ONE gooey pill ("$185 – 240") and pull apart
 *    again, with a stretchy neck, when you drag one back out.
 *  - Tap the track and the nearest handle glides there.
 *  - Digits roll as the value changes.
 *
 *     StickyRangeSlider(lower, upper, { lo, hi -> min = lo; max = hi })        // two handles
 *     StickyRangeSlider(distance, { distance = it }, bounds = 1..50, prefix = "", suffix = " km")
 *     StickyRangeSlider(lower, upper, onChange, style = StickySliderStyle.paper)   // dark surfaces
 *
 * Same names, order and defaults as the iOS `StickyRangeSlider`, with Compose's usual
 * value + callback instead of bindings. This overload has two handles.
 *
 * @param bounds smallest and largest value
 * @param step values snap to multiples of this
 * @param prefix text before a value
 * @param suffix text after a value
 * @param haptics a tick on every step and a tap when the pills fuse
 * @param accessibilityName the TalkBack label
 * @param onEditingChanged `true` when a drag starts, `false` when it ends
 */
@Composable
fun StickyRangeSlider(
    lower: Int,
    upper: Int,
    onRangeChange: (lower: Int, upper: Int) -> Unit,
    modifier: Modifier = Modifier,
    bounds: IntRange = 20..400,
    step: Int = 5,
    prefix: String = "$",
    suffix: String = "",
    style: StickySliderStyle = StickySliderStyle.ink,
    timing: StickyTiming = StickyTiming(),
    haptics: Boolean = true,
    accessibilityName: String = "Range",
    onEditingChanged: (Boolean) -> Unit = {},
) {
    StickySliderImpl(
        isRange = true,
        lower = lower,
        upper = upper,
        onChange = onRangeChange,
        modifier = modifier,
        bounds = bounds,
        step = step,
        prefix = prefix,
        suffix = suffix,
        style = style,
        timing = timing,
        haptics = haptics,
        accessibilityName = accessibilityName,
        onEditingChanged = onEditingChanged,
    )
}

/** [StickyRangeSlider] with one handle. */
@Composable
fun StickyRangeSlider(
    value: Int,
    onValueChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    bounds: IntRange = 20..400,
    step: Int = 5,
    prefix: String = "$",
    suffix: String = "",
    style: StickySliderStyle = StickySliderStyle.ink,
    timing: StickyTiming = StickyTiming(),
    haptics: Boolean = true,
    accessibilityName: String = "Value",
    onEditingChanged: (Boolean) -> Unit = {},
) {
    StickySliderImpl(
        isRange = false,
        lower = value,
        upper = bounds.last,
        onChange = { lo, _ -> onValueChange(lo) },
        modifier = modifier,
        bounds = bounds,
        step = step,
        prefix = prefix,
        suffix = suffix,
        style = style,
        timing = timing,
        haptics = haptics,
        accessibilityName = accessibilityName,
        onEditingChanged = onEditingChanged,
    )
}

// Implementation

private enum class Handle { Lower, Upper }

/** Gesture bookkeeping that doesn't need to trigger recomposition. */
private class Gesture(var lo: Int, var hi: Int) {
    var active: Handle? = null
    var grab = 0f
}

/** Where everything is right now, in dp. */
private class Geo(
    val cL: Float, val cR: Float, val mid: Float,
    val wL: Float, val wR: Float, val wM: Float,
    val m: Float, val sLo: Float, val sHi: Float,
)

@Composable
private fun StickySliderImpl(
    isRange: Boolean,
    lower: Int,
    upper: Int,
    onChange: (Int, Int) -> Unit,
    modifier: Modifier,
    bounds: IntRange,
    step: Int,
    prefix: String,
    suffix: String,
    style: StickySliderStyle,
    timing: StickyTiming,
    haptics: Boolean,
    accessibilityName: String,
    onEditingChanged: (Boolean) -> Unit,
) {
    val density = LocalDensity.current
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val animationsOff = remember { animationsOff(context) }
    val safeStep = max(step, 1)

    val sim = remember { StickySim() }
    val gesture = remember { Gesture(lower, upper) }

    // Continuous handle positions (in value units); `lower`/`upper` are these, snapped to `step`.
    var rawLo by remember { mutableDoubleStateOf(lower.toDouble()) }
    var rawHi by remember { mutableDoubleStateOf(if (isRange) upper.toDouble() else bounds.last.toDouble()) }
    var merged by remember { mutableStateOf(false) }
    var trackW by remember { mutableFloatStateOf(300f) }      // dp
    var frame by remember { mutableLongStateOf(0L) }          // bumped every frame to redraw
    var wake by remember { mutableIntStateOf(0) }             // bumped to restart the frame loop

    val curLower by rememberUpdatedState(lower)
    val curUpper by rememberUpdatedState(upper)
    val changeCallback by rememberUpdatedState(onChange)
    val editingCallback by rememberUpdatedState(onEditingChanged)
    val hapticsOn by rememberUpdatedState(haptics)

    val lowerText = "$prefix$lower$suffix"
    val upperText = "$prefix$upper$suffix"

    val tLo = StickyMath.x(rawLo, trackW, bounds)
    val tHi = if (isRange) StickyMath.x(rawHi, trackW, bounds) else tLo
    val tM = if (merged) 1f else 0f

    // External changes (the parent moved the value) when nobody is dragging.
    LaunchedEffect(lower) {
        gesture.lo = lower
        if (gesture.active == null) { rawLo = lower.toDouble(); wake++ }
    }
    LaunchedEffect(upper) {
        gesture.hi = upper
        if (gesture.active == null && isRange) { rawHi = upper.toDouble(); wake++ }
    }

    // Frame loop: runs only while something is moving, so an idle slider costs nothing.
    LaunchedEffect(wake) {
        // Restarts (every move event while dragging) must not reset the frame clock, or the
        // springs would never get a step in.
        if (!sim.running) { sim.resume(); sim.running = true }
        while (true) {
            val now = withFrameNanos { it }
            sim.step(now, tLo, tHi, tM, timing, animationsOff)
            frame = now
            if (gesture.active == null && sim.isSettled(tLo, tHi, tM)) {
                sim.running = false
                break
            }
        }
    }

    fun geo(): Geo {
        @Suppress("UNUSED_VARIABLE") val tick = frame          // subscribe the caller's phase
        val m = StickyMath.clamp01(sim.m)
        val sLo = sim.xLo
        val sHi = if (isRange) sim.xHi else sim.xLo
        val wL = StickyMath.pillWidth(lowerText)
        val wR = StickyMath.pillWidth(upperText)
        val wM = StickyMath.mergedWidth(lowerText, "$upper$suffix")
        val mid = (sLo + sHi) / 2f
        // Drawn on its own handle when apart; tucked against the other so the pair forms one
        // pill when fused.
        val cL = if (isRange) StickyMath.lerp(sLo, mid - wM / 2f + wL / 2f, m) else sLo
        val cR = StickyMath.lerp(sHi, mid + wM / 2f - wR / 2f, m)
        return Geo(cL, cR, mid, wL, wR, wM, m, sLo, sHi)
    }

    fun refreshMerged() {
        if (!isRange) { merged = false; return }
        val d = StickyMath.x(rawHi, trackW, bounds) - StickyMath.x(rawLo, trackW, bounds)
        val next = StickyMath.merged(merged, d)
        if (next != merged) {
            merged = next
            if (hapticsOn) haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }

    fun commit(lo: Int, hi: Int) {
        if (lo == gesture.lo && hi == gesture.hi) return
        gesture.lo = lo
        gesture.hi = hi
        if (hapticsOn) haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        changeCallback(lo, hi)
    }

    fun pickHandle(x: Float): Handle {
        if (!isRange) return Handle.Lower
        val mid = (sim.xLo + sim.xHi) / 2f
        if (merged) return if (x < mid) Handle.Lower else Handle.Upper   // left / right half
        return if (abs(x - sim.xLo) < abs(x - sim.xHi)) Handle.Lower else Handle.Upper
    }

    /** True when the touch landed on a pill (as opposed to empty track). */
    fun touchesPill(x: Float): Boolean {
        val slop = StickyMetrics.TAP_SLOP
        val lo = "$prefix$curLower$suffix"
        val hi = "$prefix$curUpper$suffix"
        if (!isRange) return abs(x - sim.xLo) <= StickyMath.pillWidth(lo) / 2f + slop
        if (merged) {
            val w = StickyMath.mergedWidth(lo, "$curUpper$suffix")
            return abs(x - (sim.xLo + sim.xHi) / 2f) <= w / 2f + slop
        }
        return abs(x - sim.xLo) <= StickyMath.pillWidth(lo) / 2f + slop ||
            abs(x - sim.xHi) <= StickyMath.pillWidth(hi) / 2f + slop
    }

    fun moveTo(x: Float) {
        val v = StickyMath.value(x, trackW, bounds)
        val gap = safeStep.toDouble()
        when (gesture.active) {
            Handle.Lower -> rawLo = if (isRange) min(v, rawHi - gap) else v
            Handle.Upper -> rawHi = max(v, rawLo + gap)
            null -> Unit
        }
        commit(
            StickyMath.snap(rawLo, safeStep, bounds),
            if (isRange) StickyMath.snap(rawHi, safeStep, bounds) else bounds.last,
        )
        refreshMerged()
        wake++
    }

    fun finishGesture() {
        gesture.active = null
        rawLo = gesture.lo.toDouble()                      // settle onto the snapped value
        if (isRange) rawHi = gesture.hi.toDouble()
        refreshMerged()
        wake++
        editingCallback(false)
    }

    // Accessibility: one slider for a single handle, increase/decrease actions for a range.
    fun setLower(v: Int) {
        val lo = if (isRange) min(v, curUpper - safeStep) else v
        rawLo = lo.toDouble(); commit(StickyMath.snap(rawLo, safeStep, bounds), gesture.hi)
        refreshMerged(); wake++
    }
    fun setUpper(v: Int) {
        val hi = max(v, curLower + safeStep)
        rawHi = hi.toDouble(); commit(gesture.lo, StickyMath.snap(rawHi, safeStep, bounds))
        refreshMerged(); wake++
    }

    val gooEffect = remember(density.density) {
        if (Build.VERSION.SDK_INT >= 31) gooRenderEffect(StickyMetrics.GOO_BLUR * density.density) else null
    }
    val shadowEffect = remember(density.density) {
        if (Build.VERSION.SDK_INT >= 31) softShadowRenderEffect(StickyMetrics.SHADOW_BLUR * density.density) else null
    }

    Box(
        modifier
            .fillMaxWidth()
            .height(StickyMetrics.HEIGHT.dp)
            .onSizeChanged { size ->
                val w = max(1f, size.width / density.density - 2 * StickyMetrics.INSET)
                trackW = w
                if (isRange) {
                    val d = StickyMath.x(rawHi, w, bounds) - StickyMath.x(rawLo, w, bounds)
                    merged = StickyMath.merged(merged, d)
                }
                val xl = StickyMath.x(rawLo, w, bounds)
                sim.snapTo(xl, if (isRange) StickyMath.x(rawHi, w, bounds) else xl, if (merged) 1f else 0f)
                frame++
            }
            .pointerInput(bounds, safeStep, isRange, prefix, suffix) {
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
                    val d = density.density
                    val startX = down.position.x / d
                    val handle = pickHandle(startX)
                    gesture.active = handle
                    editingCallback(true)
                    if (touchesPill(startX)) {
                        sim.glide = false
                        gesture.grab = startX -
                            StickyMath.x(if (handle == Handle.Lower) rawLo else rawHi, trackW, bounds)
                    } else {
                        // Tapped the bare track: send the nearest handle there.
                        sim.glide = true
                        gesture.grab = 0f
                    }
                    moveTo(startX - gesture.grab)
                    down.consume()
                    while (true) {
                        val event = awaitPointerEvent()
                        val change = event.changes.firstOrNull { it.id == down.id } ?: break
                        if (!change.pressed) { change.consume(); break }
                        val x = change.position.x / d
                        // Once the finger really drags, go back to the tight follow spring.
                        if (sim.glide && abs(x - startX) > StickyMetrics.DRAG_START) sim.glide = false
                        moveTo(x - gesture.grab)
                        change.consume()
                    }
                    finishGesture()
                }
            }
            .semantics {
                contentDescription = accessibilityName
                if (isRange) {
                    stateDescription = "$prefix$lower$suffix to $upper$suffix"
                    customActions = listOf(
                        CustomAccessibilityAction("Increase minimum") { setLower(curLower + safeStep); true },
                        CustomAccessibilityAction("Decrease minimum") { setLower(curLower - safeStep); true },
                        CustomAccessibilityAction("Increase maximum") { setUpper(curUpper + safeStep); true },
                        CustomAccessibilityAction("Decrease maximum") { setUpper(curUpper - safeStep); true },
                    )
                } else {
                    stateDescription = lowerText
                    progressBarRangeInfo = ProgressBarRangeInfo(
                        current = lower.toFloat(),
                        range = bounds.first.toFloat()..bounds.last.toFloat(),
                        steps = max(0, (bounds.last - bounds.first) / safeStep - 1),
                    )
                    setProgress { target -> setLower(target.roundToInt()); true }
                }
            },
    ) {
        // Track and the part between the handles
        Canvas(Modifier.fillMaxSize()) {
            val g = geo()
            val d = this.density
            val cy = size.height / 2f
            val th = StickyMetrics.TRACK_HEIGHT * d
            drawRoundRect(
                color = style.track,
                topLeft = Offset(StickyMetrics.INSET * d, cy - th / 2f),
                size = Size(trackW * d, th),
                cornerRadius = CornerRadius(th / 2f),
            )
            val a = if (isRange) g.sLo else StickyMetrics.INSET
            val b = if (isRange) g.sHi else g.sLo
            drawRect(
                color = style.trackFill,
                topLeft = Offset(a * d, cy - th / 2f),
                size = Size(max(0f, b - a) * d, th),
            )
        }

        // Soft drop shadow under the pills (Android 12+)
        if (shadowEffect != null) {
            Canvas(Modifier.fillMaxSize().graphicsLayer { renderEffect = shadowEffect }) {
                drawPills(geo(), isRange, style.shadow, dyDp = 2f)
            }
        }

        // Goo: blur + alpha threshold fuses shapes that are close together (Android 12+).
        // Below that the pills are drawn plain and simply overlap.
        Canvas(
            Modifier.fillMaxSize().graphicsLayer {
                if (gooEffect != null) {
                    renderEffect = gooEffect
                    compositingStrategy = CompositingStrategy.Offscreen
                }
            },
        ) {
            drawPills(geo(), isRange, style.pill)
        }

        // Labels
        Floating(centerX = { geo().cL }, opacity = { if (isRange) StickyMath.clamp01(1.5f - 2f * geo().m) else 1f }) {
            RollingText(lowerText, lower, style.label, timing.digitRoll, animationsOff)
        }
        if (isRange) {
            Floating(centerX = { geo().cR }, opacity = { StickyMath.clamp01(1.5f - 2f * geo().m) }) {
                RollingText(upperText, upper, style.label, timing.digitRoll, animationsOff)
            }
            Floating(centerX = { geo().mid }, opacity = { StickyMath.clamp01(2f * geo().m - 0.5f) }) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(
                        ((StickyMetrics.DASH_WIDTH - StickyMetrics.DASH_GLYPH) / 2f).dp,
                    ),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    RollingText(lowerText, lower, style.label, timing.digitRoll, animationsOff)
                    Box(Modifier.width(StickyMetrics.DASH_GLYPH.dp), contentAlignment = Alignment.Center) {
                        BasicText("–", style = labelStyle(style.label.copy(alpha = 0.6f)))
                    }
                    RollingText("$upper$suffix", upper, style.label, timing.digitRoll, animationsOff)
                }
            }
        }
    }
}

private fun DrawScope.drawPills(g: Geo, isRange: Boolean, color: Color, dyDp: Float = 0f) {
    val d = density
    val cy = size.height / 2f
    val h = StickyMetrics.PILL_HEIGHT * d
    val r = CornerRadius(StickyMetrics.PILL_RADIUS * d)
    val dy = dyDp * d
    drawRoundRect(color, Offset((g.cL - g.wL / 2f) * d, cy - h / 2f + dy), Size(g.wL * d, h), r)
    if (isRange) {
        drawRoundRect(color, Offset((g.cR - g.wR / 2f) * d, cy - h / 2f + dy), Size(g.wR * d, h), r)
        // A thin bridge: the neck that stretches between the pills as they part.
        drawRect(color, Offset(g.cL * d, cy - 3.5f * d + dy), Size(max(0f, g.cR - g.cL) * d, 7f * d))
    }
}

/** Places [content] centered on `centerX()` dp, re-placing every frame without recomposing. */
@Composable
private fun Floating(centerX: () -> Float, opacity: () -> Float, content: @Composable () -> Unit) {
    val density = LocalDensity.current.density
    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer { alpha = opacity() }
            .layout { measurable, constraints ->
                val p = measurable.measure(Constraints())
                layout(constraints.maxWidth, constraints.maxHeight) {
                    p.place(
                        (centerX() * density - p.width / 2f).roundToInt(),
                        ((constraints.maxHeight - p.height) / 2f).roundToInt(),
                    )
                }
            },
    ) { content() }
}

private fun labelStyle(color: Color) = TextStyle(
    color = color,
    fontSize = StickyMetrics.FONT_SIZE.sp,
    fontWeight = FontWeight.Medium,
    fontFeatureSettings = "tnum",
)

/** Text whose characters roll up or down when the value changes, like an odometer. */
@Composable
private fun RollingText(text: String, value: Int, color: Color, durationSeconds: Double, instant: Boolean) {
    val previous = remember { intArrayOf(value) }
    val goingUp = value >= previous[0]
    SideEffect { previous[0] = value }
    val ms = (durationSeconds * 1000).roundToInt()

    Row(Modifier.clipToBounds()) {
        text.forEachIndexed { i, ch ->
            // Keyed from the right so a digit keeps its identity when the number gains a digit.
            key(text.length - i) {
                AnimatedContent(
                    targetState = ch,
                    transitionSpec = {
                        if (instant) {
                            EnterTransition.None togetherWith ExitTransition.None
                        } else {
                            val dir = if (goingUp) 1 else -1
                            (slideInVertically(tween(ms)) { it * dir } + fadeIn(tween(ms))) togetherWith
                                (slideOutVertically(tween(ms)) { -it * dir } + fadeOut(tween(ms)))
                        }
                    },
                    label = "digit",
                ) { c -> BasicText(c.toString(), style = labelStyle(color)) }
            }
        }
    }
}

/** Animations off (developer option or battery saver) shows instant moves. */
private fun animationsOff(context: Context): Boolean = try {
    Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
} catch (e: Exception) {
    false
}

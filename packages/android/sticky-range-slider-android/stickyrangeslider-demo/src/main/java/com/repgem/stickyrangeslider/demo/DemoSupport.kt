//
//  DemoSupport.kt
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
//  Shared pieces for the dark and light demo screens (plain Compose foundation, no Material).
//
package com.repgem.stickyrangeslider.demo

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.repgem.stickyrangeslider.StickyRangeSlider
import com.repgem.stickyrangeslider.StickySliderStyle
import com.repgem.stickyrangeslider.StickyTiming
import kotlin.math.exp
import kotlin.math.pow

/** Colors for one demo theme. */
internal class DemoTheme(val dark: Boolean) {
    val page = if (dark) Color(0.07f, 0.07f, 0.07f) else Color(0.96f, 0.96f, 0.97f)
    val card = if (dark) Color(0.11f, 0.11f, 0.11f) else Color.White
    val ink = if (dark) Color(0.96f, 0.96f, 0.96f) else Color(0.10f, 0.11f, 0.14f)
    val subtle = if (dark) Color.White.copy(alpha = 0.45f) else Color(0.45f, 0.47f, 0.52f)
    val hairline = if (dark) Color.White.copy(alpha = 0.08f) else Color.Black.copy(alpha = 0.06f)
    val barOff = if (dark) Color.White.copy(alpha = 0.12f) else Color.Black.copy(alpha = 0.09f)
    val style = if (dark) StickySliderStyle.paper else StickySliderStyle.ink
    val buttonText = if (dark) Color(0.10f, 0.10f, 0.10f) else Color.White
}

/** Text with a size in sp and tabular digits. */
@Composable
internal fun Txt(
    text: String,
    size: Float,
    color: Color,
    weight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier,
) {
    BasicText(
        text = text,
        modifier = modifier,
        style = TextStyle(color = color, fontSize = size.sp, fontWeight = weight, fontFeatureSettings = "tnum"),
    )
}

/** Fake listings: how many stays there are at each price, for the histogram demo. */
internal object PriceData {
    const val START = 20
    const val BIN_WIDTH = 8

    val counts: List<Int> = List(48) { i ->
        val x = (START + i * BIN_WIDTH + BIN_WIDTH / 2).toDouble()
        val main = 220 * exp(-((x - 105) / 60).pow(2))
        val luxury = 70 * exp(-((x - 290) / 55).pow(2))
        Math.round(main + luxury).toInt() + 4
    }

    fun isInside(bin: Int, lo: Int, hi: Int): Boolean {
        val centre = START + bin * BIN_WIDTH + BIN_WIDTH / 2
        return centre in lo..hi
    }

    fun stays(lo: Int, hi: Int): Int {
        var total = 0
        counts.forEachIndexed { i, c -> if (isInside(i, lo, hi)) total += c }
        return (total * 0.12).toInt()
    }
}

@Composable
internal fun PriceHistogram(lo: Int, hi: Int, theme: DemoTheme) {
    val peak = (PriceData.counts.maxOrNull() ?: 1).toFloat()
    Row(
        Modifier.fillMaxWidth().height(84.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        PriceData.counts.forEachIndexed { i, count ->
            val color by animateColorAsState(
                if (PriceData.isInside(i, lo, hi)) theme.ink else theme.barOff,
                tween(140),
                label = "bar",
            )
            Box(
                Modifier
                    .weight(1f)
                    .height(maxOf(2f, count / peak * 84f).dp)
                    .background(color, RoundedCornerShape(1.5.dp)),
            )
        }
    }
}

@Composable
internal fun DemoSection(title: String, theme: DemoTheme, content: @Composable () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Txt(title, 12f, theme.subtle, FontWeight.Medium)
        content()
    }
}

@Composable
internal fun DemoCard(theme: DemoTheme, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(26.dp)
    Column(
        Modifier
            .width(340.dp)
            .then(
                if (theme.dark) Modifier else Modifier.shadow(
                    10.dp, shape,
                    ambientColor = Color.Black.copy(alpha = 0.06f),
                    spotColor = Color.Black.copy(alpha = 0.06f),
                ),
            )
            .background(theme.card, shape)
            .border(1.dp, theme.hairline, shape)
            .padding(vertical = 20.dp),
    ) { content() }
}

/** The hero demo: a price filter with a histogram that follows the handles. */
@Composable
internal fun PriceFilterCard(theme: DemoTheme) {
    var lo by remember { mutableIntStateOf(85) }
    var hi by remember { mutableIntStateOf(240) }
    val stays = PriceData.stays(lo, hi)

    DemoCard(theme) {
        Column(Modifier.padding(horizontal = 30.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Txt("Price per night", 15f, theme.ink, FontWeight.SemiBold)
            Txt("Includes all fees, before taxes", 12f, theme.subtle)
        }
        Box(Modifier.padding(start = 30.dp, end = 30.dp, top = 14.dp)) {
            PriceHistogram(lo, hi, theme)
        }
        StickyRangeSlider(
            lower = lo,
            upper = hi,
            onRangeChange = { l, h -> lo = l; hi = h },
            bounds = 20..400,
            step = 5,
            style = theme.style,
            accessibilityName = "Price per night",
        )
        Row(
            Modifier.fillMaxWidth().padding(start = 30.dp, end = 30.dp, top = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Box(Modifier.tappable { lo = 20; hi = 400 }) { Txt("Clear", 13f, theme.subtle, FontWeight.Medium) }
            Row(
                Modifier
                    .background(theme.ink, RoundedCornerShape(11.dp))
                    .padding(horizontal = 14.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Txt("Show ", 13f, theme.buttonText, FontWeight.Medium)
                AnimatedContent(
                    targetState = stays,
                    transitionSpec = {
                        val dir = if (targetState > initialState) 1 else -1
                        (slideInVertically(tween(280)) { it * dir } + fadeIn(tween(280))) togetherWith
                            (slideOutVertically(tween(280)) { -it * dir } + fadeOut(tween(280)))
                    },
                    label = "stays",
                ) { n -> Txt("$n", 13f, theme.buttonText, FontWeight.Medium) }
                Txt(" stays", 13f, theme.buttonText, FontWeight.Medium)
            }
        }
    }
}

/** A titled two-handle slider inside a card, with its own state. */
@Composable
internal fun RangeDemo(
    title: String,
    theme: DemoTheme,
    initialLower: Int,
    initialUpper: Int,
    bounds: IntRange = 20..400,
    step: Int = 5,
    prefix: String = "$",
    suffix: String = "",
    style: StickySliderStyle? = null,
    timing: StickyTiming = StickyTiming(),
) {
    var lo by remember { mutableIntStateOf(initialLower) }
    var hi by remember { mutableIntStateOf(initialUpper) }
    DemoCard(theme) {
        Box(Modifier.padding(horizontal = 30.dp)) { Txt(title, 13f, theme.subtle, FontWeight.Medium) }
        StickyRangeSlider(
            lower = lo,
            upper = hi,
            onRangeChange = { l, h -> lo = l; hi = h },
            bounds = bounds,
            step = step,
            prefix = prefix,
            suffix = suffix,
            style = style ?: theme.style,
            timing = timing,
            accessibilityName = title,
        )
    }
}

/** A titled one-handle slider inside a card, with its own state. */
@Composable
internal fun SingleDemo(
    title: String,
    theme: DemoTheme,
    initialValue: Int,
    bounds: IntRange = 20..400,
    step: Int = 5,
    prefix: String = "$",
    suffix: String = "",
) {
    var value by remember { mutableIntStateOf(initialValue) }
    DemoCard(theme) {
        Box(Modifier.padding(horizontal = 30.dp)) { Txt(title, 13f, theme.subtle, FontWeight.Medium) }
        StickyRangeSlider(
            value = value,
            onValueChange = { value = it },
            bounds = bounds,
            step = step,
            prefix = prefix,
            suffix = suffix,
            style = theme.style,
            accessibilityName = title,
        )
    }
}

/** Everything the dark and light showcases have in common. */
@Composable
internal fun ExampleStack(theme: DemoTheme) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(30.dp),
    ) {
        PriceFilterCard(theme)

        DemoSection("One handle · tap anywhere on the track", theme) {
            SingleDemo("Max distance", theme, initialValue = 12, bounds = 1..50, step = 1, prefix = "", suffix = " km")
        }
        DemoSection("Any range, any unit", theme) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                RangeDemo("Salary", theme, 85, 140, bounds = 40..200, step = 5, prefix = "$", suffix = "k")
                RangeDemo("Age", theme, 24, 38, bounds = 18..65, step = 1, prefix = "")
            }
        }
        DemoSection("Your colors", theme) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                RangeDemo("Blue", theme, 60, 220, style = StickySliderStyle.accent(Color(0.20f, 0.52f, 1.00f)))
                RangeDemo("Green", theme, 110, 180, style = StickySliderStyle.accent(Color(0.12f, 0.72f, 0.45f)))
                RangeDemo("Orange", theme, 40, 300, style = StickySliderStyle.accent(Color(1.00f, 0.55f, 0.25f)))
            }
        }
        DemoSection("Lazy follow (slower springs)", theme) {
            RangeDemo(
                "Heavy handles", theme, 90, 260,
                timing = StickyTiming(follow = 0.45, glide = 0.6, merge = 0.4),
            )
        }
    }
}

/**
 * A tappable control that does nothing by default. Like a plain `Button` on iOS, it dims and
 * shrinks slightly while pressed, so it feels clickable.
 */
internal fun Modifier.tappable(onClick: () -> Unit = {}): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val alpha by animateFloatAsState(if (pressed) 0.55f else 1f, tween(90), label = "pressAlpha")
    val scale by animateFloatAsState(if (pressed) 0.95f else 1f, tween(90), label = "pressScale")
    this
        .graphicsLayer { this.alpha = alpha; scaleX = scale; scaleY = scale }
        .clickable(interactionSource = source, indication = null, onClick = onClick)
}

//
//  DemoSupport.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Small helpers shared by the demo screens (plain Compose foundation, no Material needed).
//
package com.repgem.dragablecards.demo

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.Alignment
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Text with a size in sp. */
@Composable
internal fun Txt(
    text: String,
    size: Float,
    color: Color = Color.White,
    weight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier,
    maxLines: Int = Int.MAX_VALUE,
) {
    BasicText(
        text = text,
        modifier = modifier,
        style = TextStyle(color = color, fontSize = size.sp, fontWeight = weight),
        maxLines = maxLines,
    )
}

/** Plain text field with a placeholder. */
@Composable
internal fun PlainField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    size: Float,
    textColor: Color,
    hintColor: Color,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        singleLine = singleLine,
        textStyle = TextStyle(color = textColor, fontSize = size.sp),
        cursorBrush = SolidColor(textColor),
        decorationBox = { inner ->
            Box {
                if (value.isEmpty()) Txt(placeholder, size, hintColor)
                inner()
            }
        },
    )
}

/**
 * A tappable control that does nothing by default (demo buttons). Like a plain `Button` on iOS,
 * it dims and shrinks slightly while pressed, so it feels clickable.
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

/** Colors shared by the demo boards so the same layout can be shown dark or light. */
internal class DemoTheme(
    val page: Color,
    val column: Color,
    val columnBorder: Color,
    val card: Color,
    val cardBorder: Color,
    val text: Color,
    val muted: Color,
    val pill: Color,
    val placeholder: Color,
    /** Green, blue, yellow, purple: the status colors of the project board. */
    val accents: List<Color>,
)

internal val DarkTheme = DemoTheme(
    page = Color(0xFF161616),
    column = Color(0xFF1E1E1E),
    columnBorder = Color(0xFF34393F),
    card = Color(0xFF2A2A2A),
    cardBorder = Color(0xFF3A3F45),
    text = Color(0xEBFFFFFF),
    muted = Color(0x99FFFFFF),
    pill = Color(0x14FFFFFF),
    placeholder = Color(0xFF262626),
    accents = listOf(Color(0xFF3FB950), Color(0xFF58A6FF), Color(0xFFD29922), Color(0xFFA371F7)),
)

internal val LightTheme = DemoTheme(
    page = Color.White,
    column = Color(0xFFF6F8FA),
    columnBorder = Color(0xFFD0D7DE),
    card = Color.White,
    cardBorder = Color(0xFFD0D7DE),
    text = Color(0xFF1F2328),
    muted = Color(0xFF59636E),
    pill = Color.White,
    placeholder = Color(0xFFE6EAEF),
    accents = listOf(Color(0xFF1A7F37), Color(0xFF0969DA), Color(0xFFBF8700), Color(0xFF8250DF)),
)

/** A labelled demo block. */
@Composable
internal fun DemoSection(title: String, theme: DemoTheme, content: @Composable () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Txt(title, 12f, theme.muted, FontWeight.Medium)
        content()
    }
}

/** Initials in a colored circle. */
@Composable
internal fun AvatarDot(initials: String, color: Color, size: Int = 20) {
    Box(Modifier.size(size.dp).background(color, CircleShape), contentAlignment = Alignment.Center) {
        Txt(initials, size * 0.4f, Color.White, FontWeight.Bold)
    }
}

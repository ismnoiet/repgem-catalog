//
//  BoardsMedia.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Media-style showcase board: a music queue (the live equalizer keeps moving while the card is
//  lifted, and the header totals update as songs move).
//
package com.repgem.dragablecards.demo

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.repgem.dragablecards.ColumnStyle
import com.repgem.dragablecards.DragAppearance
import com.repgem.dragablecards.DragBoard
import com.repgem.dragablecards.rememberDragBoardState

// ---- Music queue -------------------------------------------------------------------------------

private class Song(
    val id: Int,
    val title: String,
    val artist: String,
    val seconds: Int,
    val art: Pair<Color, Color>,
    val playing: Boolean = false,
)

private val sunsetArt = Color(0xFFFF8A5B) to Color(0xFFD6336C)
private val tideArt = Color(0xFF38BDF8) to Color(0xFF4338CA)
private val fernArt = Color(0xFF86EFAC) to Color(0xFF0F766E)
private val duskArt = Color(0xFFC4B5FD) to Color(0xFF6D28D9)
private val honeyArt = Color(0xFFFDE68A) to Color(0xFFEA580C)
private val inkArt = Color(0xFF64748B) to Color(0xFF0F172A)
private val roseArt = Color(0xFFFBCFE8) to Color(0xFFDB2777)

private fun songs(): List<List<Song>> = listOf(
    listOf(
        Song(1, "Neon Harbor", "Kite Season", 214, sunsetArt, playing = true),
        Song(2, "Slow Orbit", "Lumen", 187, tideArt),
        Song(3, "Paper Planes at Noon", "Okra", 203, honeyArt),
        Song(4, "Static Bloom", "Vela", 241, duskArt),
    ),
    listOf(
        Song(5, "Glass Garden", "Nori", 196, fernArt),
        Song(6, "Low Tide Radio", "Pelham", 228, inkArt),
        Song(7, "Cinder", "Aya Moreau", 175, roseArt),
    ),
)

@Composable
internal fun MusicQueue(theme: DemoTheme, modifier: Modifier = Modifier) {
    val state = rememberDragBoardState(songs()) { it.id }
    DragBoard(
        state = state,
        modifier = modifier.fillMaxWidth().height(380.dp),
        columnWidth = 318.dp,
        cardSpacing = 6.dp,
        columnStyle = ColumnStyle(background = theme.column, border = theme.columnBorder, shape = RoundedCornerShape(18.dp)),
        appearance = DragAppearance(cornerRadius = 14.dp, liftScale = 1.05f, placeholderFill = theme.placeholder, placeholderBorder = theme.columnBorder),
        header = { index, items ->
            val minutes = items.sumOf { it.seconds } / 60
            Row(
                Modifier.fillMaxWidth().padding(start = 2.dp, end = 2.dp, bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (index == 1) Symbol(Sym.HeartFill, 14f, Color(0xFFEC4899))
                Txt(if (index == 0) "Up next" else "Liked", 14f, theme.text, FontWeight.SemiBold)
                Txt("${items.size} songs  ·  $minutes min", 12f, theme.muted)
            }
        },
    ) { song ->
        SongCard(theme, song)
    }
}

@Composable
private fun SongCard(theme: DemoTheme, song: Song) {
    val shape = RoundedCornerShape(14.dp)
    Row(
        Modifier.fillMaxWidth().background(theme.card, shape).border(1.dp, theme.cardBorder, shape).padding(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            Modifier
                .size(46.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(Brush.linearGradient(listOf(song.art.first, song.art.second))),
            contentAlignment = Alignment.Center,
        ) {
            if (song.playing) Equalizer(Color.White)
        }
        Column(Modifier.weight(1f)) {
            Txt(song.title, 14f, theme.text, FontWeight.SemiBold, maxLines = 1)
            Txt(song.artist, 12f, theme.muted, maxLines = 1)
        }
        Txt("${song.seconds / 60}:${(song.seconds % 60).toString().padStart(2, '0')}", 12f, theme.muted, modifier = Modifier.padding(end = 6.dp))
    }
}

/** Three bouncing bars. It keeps animating on the floating copy while the card is lifted. */
@Composable
private fun Equalizer(color: Color) {
    val transition = rememberInfiniteTransition(label = "equalizer")
    Row(
        Modifier.height(18.dp),
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(2.5.dp),
    ) {
        for (ms in listOf(520, 380, 450)) {
            val level by transition.animateFloat(
                initialValue = 0.25f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(tween(ms, easing = LinearEasing), RepeatMode.Reverse),
                label = "bar",
            )
            Box(Modifier.width(3.dp).fillMaxHeight(level).background(color, RoundedCornerShape(1.5.dp)))
        }
    }
}

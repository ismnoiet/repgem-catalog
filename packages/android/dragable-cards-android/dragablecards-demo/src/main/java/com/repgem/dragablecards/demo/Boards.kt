//
//  Boards.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  The GitHub-style project board, themed so the dark and light pages show exactly the same layout.
//
package com.repgem.dragablecards.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.repgem.dragablecards.ColumnStyle
import com.repgem.dragablecards.DragAppearance
import com.repgem.dragablecards.DragBoard
import com.repgem.dragablecards.rememberDragBoardState

// ---- Project board -----------------------------------------------------------------------------

private class Issue(
    val id: Int,
    val title: String,
    val estimate: Int = 1,
    val avatar: Pair<String, Color>? = null,
    val tracking: Boolean = false,
)

private class StatusColumn(val title: String, val subtitle: String, val accent: Int, val limit: Int?)

private val statusColumns = listOf(
    StatusColumn("Backlog", "This item hasn't been started", accent = 0, limit = 5),
    StatusColumn("Ready", "This is ready to be picked up", accent = 1, limit = null),
    StatusColumn("In progress", "This is actively being worked on", accent = 2, limit = 3),
    StatusColumn("In review", "This item is in review", accent = 3, limit = 5),
)

private val jd = "JD" to Color(0xFF2D333B)
private val am = "AM" to Color(0xFFB5651D)
private val tk = "TK" to Color(0xFF6E4B8B)

private fun projectIssues(): List<List<Issue>> = listOf(
    listOf(
        Issue(1366, "Explore a bug"),
        Issue(821, "Updates to alien, beam, bomb and cannon sprites", estimate = 2, avatar = am),
    ),
    listOf(Issue(797, "Easter egg with high score unlocking new paid levels", avatar = jd)),
    listOf(
        Issue(1304, "Make sure that it delights customers", avatar = jd),
        Issue(829, "Hero site - Copy"),
    ),
    listOf(Issue(1101, "[Tracking] Integrate payments system", avatar = tk, tracking = true)),
)

@Composable
internal fun ProjectBoard(theme: DemoTheme, modifier: Modifier = Modifier) {
    val state = rememberDragBoardState(projectIssues()) { it.id }
    DragBoard(
        state = state,
        modifier = modifier.fillMaxWidth().height(430.dp),
        columnStyle = ColumnStyle(background = theme.column, border = theme.columnBorder),
        appearance = DragAppearance(placeholderFill = theme.placeholder, placeholderBorder = theme.columnBorder),
        header = { index, issues -> ProjectHeader(theme, statusColumns[index], issues) },
    ) { issue ->
        IssueCard(theme, issue)
    }
}

@Composable
internal fun Pill(theme: DemoTheme, text: String) {
    Box(
        Modifier
            .background(theme.pill, CircleShape)
            .border(1.dp, theme.columnBorder, CircleShape)
            .padding(horizontal = 6.dp, vertical = 1.5.dp),
    ) { Txt(text, 11f, theme.muted, FontWeight.Medium, maxLines = 1) }
}

@Composable
private fun ProjectHeader(theme: DemoTheme, column: StatusColumn, issues: List<Issue>) {
    Column(Modifier.padding(bottom = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.size(14.dp).border(2.dp, theme.accents[column.accent], CircleShape))
            Txt(column.title, 14f, theme.text, FontWeight.SemiBold, maxLines = 1)
            Pill(theme, column.limit?.let { "${issues.size}/$it" } ?: "${issues.size}")
            Pill(theme, "Estimate: ${issues.sumOf { it.estimate }}")
            Spacer(Modifier.weight(1f))
            Symbol(Sym.Ellipsis, 16f, theme.muted)
        }
        Txt(column.subtitle, 13f, theme.muted, modifier = Modifier.padding(top = 4.dp))
    }
}

@Composable
private fun IssueCard(theme: DemoTheme, issue: Issue) {
    val shape = RoundedCornerShape(6.dp)
    Column(
        Modifier
            .fillMaxWidth()
            .background(theme.card, shape)
            .border(1.dp, theme.cardBorder, shape)
            .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Symbol(
                if (issue.tracking) Sym.CheckCircle else Sym.IssueOpen,
                13f,
                if (issue.tracking) theme.accents[3] else theme.accents[0],
            )
            Txt("planning-tracking-demo #${issue.id}", 12f, theme.muted, maxLines = 1, modifier = Modifier.weight(1f, fill = false))
            Spacer(Modifier.weight(1f))
            issue.avatar?.let { AvatarDot(it.first, it.second) }
        }
        Txt(issue.title, 14f, theme.text)
    }
}

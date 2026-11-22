//
//  BoardsPlanning.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Planning-style showcase boards: a hiring pipeline (reports every move through `onMove`), a weekly
//  meal planner (five columns, so the board scrolls sideways as you drag) and a trip planner (card
//  height follows the content, and a day turns amber when it is overbooked).
//
package com.repgem.dragablecards.demo

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.repgem.dragablecards.ColumnStyle
import com.repgem.dragablecards.DragAppearance
import com.repgem.dragablecards.DragBoard
import com.repgem.dragablecards.rememberDragBoardState
import kotlinx.coroutines.delay

// ---- Hiring pipeline ---------------------------------------------------------------------------

private class Candidate(
    val id: Int,
    val name: String,
    val role: String,
    val score: Int,
    val tags: List<String>,
    val tone: Pair<Color, Color>,
)

private val stages = listOf("Applied", "Interview", "Offer", "Hired")
/** Index into the theme accents (green, blue, yellow, purple) for each stage. */
private val stageAccent = listOf(1, 2, 3, 0)

private val coral = Color(0xFFFF7A59) to Color(0xFFE23E7B)
private val ocean = Color(0xFF38BDF8) to Color(0xFF6366F1)
private val mint = Color(0xFF34D399) to Color(0xFF0EA5A4)
private val amber = Color(0xFFFBBF24) to Color(0xFFF97316)
private val orchid = Color(0xFFC084FC) to Color(0xFF7C3AED)
private val slate = Color(0xFF94A3B8) to Color(0xFF475569)

private fun candidates(): List<List<Candidate>> = listOf(
    listOf(
        Candidate(1, "Maya Chen", "Senior Android Engineer", 88, listOf("Remote", "Senior"), coral),
        Candidate(2, "Jonas Weber", "Product Designer", 74, listOf("Referral"), ocean),
        Candidate(3, "Priya Nair", "Compose Engineer", 81, listOf("Remote"), mint),
    ),
    listOf(Candidate(4, "Leo Martins", "Design Systems Lead", 91, listOf("Onsite", "Lead"), amber)),
    listOf(Candidate(5, "Amira Haddad", "Staff Engineer", 95, listOf("Remote", "Staff"), orchid)),
    listOf(Candidate(6, "Tom Okafor", "QA Engineer", 79, listOf("Hybrid"), slate)),
)

@Composable
internal fun HiringBoard(theme: DemoTheme, modifier: Modifier = Modifier) {
    val state = rememberDragBoardState(candidates()) { it.id }
    var toast by remember { mutableStateOf<String?>(null) }
    var lastToast by remember { mutableStateOf("") }
    LaunchedEffect(toast) {
        if (toast != null) {
            delay(1700)
            toast = null
        }
    }
    val toastAlpha by animateFloatAsState(if (toast != null) 1f else 0f, tween(220), label = "toast")

    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        // Fed by `onMove`: the board tells you where a card landed.
        Box(
            Modifier.height(30.dp).graphicsLayer { alpha = toastAlpha; translationY = (1f - toastAlpha) * -8.dp.toPx() },
            contentAlignment = Alignment.Center,
        ) {
            Row(
                Modifier
                    .background(theme.card, CircleShape)
                    .border(1.dp, theme.cardBorder, CircleShape)
                    .padding(horizontal = 12.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Symbol(Sym.Check, 12f, theme.accents[0], 2.8f)
                Txt(lastToast, 12f, theme.text, FontWeight.Medium)
            }
        }
        DragBoard(
            state = state,
            modifier = Modifier.fillMaxWidth().height(390.dp),
            columnWidth = 252.dp,
            columnStyle = ColumnStyle(background = theme.column, border = theme.columnBorder, shape = RoundedCornerShape(16.dp)),
            appearance = DragAppearance(cornerRadius = 12.dp, placeholderFill = theme.placeholder, placeholderBorder = theme.columnBorder),
            onMove = { candidate, from, to, _ ->
                if (from != to) {
                    lastToast = "${candidate.name} moved to ${stages[to]}"
                    toast = lastToast
                }
            },
            header = { index, people ->
                Row(
                    Modifier.fillMaxWidth().padding(start = 2.dp, end = 2.dp, bottom = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Box(Modifier.size(8.dp).background(theme.accents[stageAccent[index]], CircleShape))
                    Txt(stages[index], 14f, theme.text, FontWeight.SemiBold)
                    Txt("${people.size}", 13f, theme.muted)
                    Spacer(Modifier.weight(1f))
                    if (people.isNotEmpty()) Txt("avg ${people.sumOf { it.score } / people.size}", 11f, theme.muted)
                }
            },
        ) { candidate ->
            CandidateCard(theme, candidate)
        }
    }
}

@Composable
private fun CandidateCard(theme: DemoTheme, c: Candidate) {
    val shape = RoundedCornerShape(12.dp)
    Column(
        Modifier.fillMaxWidth().background(theme.card, shape).border(1.dp, theme.cardBorder, shape).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                Modifier.size(36.dp).background(Brush.linearGradient(listOf(c.tone.first, c.tone.second)), CircleShape),
                contentAlignment = Alignment.Center,
            ) { Txt(c.name.split(" ").map { it.first() }.joinToString(""), 13f, Color.White, FontWeight.Bold) }
            Column(Modifier.weight(1f)) {
                Txt(c.name, 14f, theme.text, FontWeight.SemiBold, maxLines = 1)
                Txt(c.role, 12f, theme.muted, maxLines = 1)
            }
            val ring = when {
                c.score >= 90 -> theme.accents[0]
                c.score >= 80 -> theme.accents[1]
                else -> theme.accents[2]
            }
            Box(Modifier.size(30.dp).border(2.dp, ring, CircleShape), contentAlignment = Alignment.Center) {
                Txt("${c.score}", 11f, theme.text, FontWeight.Bold)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            c.tags.forEach { Pill(theme, it) }
        }
    }
}

// ---- Weekly meal planner -----------------------------------------------------------------------

private class Meal(val id: Int, val type: Int, val name: String, val kcal: Int)

private val mealTypes = listOf("BREAKFAST", "LUNCH", "DINNER", "SNACK")
private val mealColors = listOf(Color(0xFFF59E0B), Color(0xFF22C55E), Color(0xFF8B5CF6), Color(0xFFEC4899))
private val weekDays = listOf("Mon" to 16, "Tue" to 17, "Wed" to 18, "Thu" to 19, "Fri" to 20)

private fun meals(): List<List<Meal>> = listOf(
    listOf(Meal(1, 0, "Overnight oats", 320), Meal(2, 1, "Chicken grain bowl", 610), Meal(3, 2, "Salmon and greens", 540)),
    listOf(Meal(4, 0, "Veggie omelette", 380), Meal(5, 1, "Lentil soup", 430), Meal(6, 2, "Pasta al limone", 640)),
    listOf(Meal(7, 0, "Yogurt and berries", 280), Meal(8, 1, "Greek salad", 390), Meal(9, 3, "Apple and almonds", 210)),
    listOf(Meal(10, 0, "Green smoothie", 260), Meal(11, 1, "Falafel wrap", 520)),
    listOf(Meal(12, 2, "Friday pizza night", 820)),
)

@Composable
internal fun MealPlanner(theme: DemoTheme, modifier: Modifier = Modifier) {
    val state = rememberDragBoardState(meals()) { it.id }
    DragBoard(
        state = state,
        modifier = modifier.fillMaxWidth().height(420.dp),
        columnWidth = 190.dp,
        cardSpacing = 8.dp,
        columnStyle = ColumnStyle(background = theme.column, border = theme.columnBorder, shape = RoundedCornerShape(16.dp)),
        appearance = DragAppearance(cornerRadius = 10.dp, liftTilt = 3f, placeholderFill = theme.placeholder, placeholderBorder = theme.columnBorder),
        header = { index, items ->
            val (day, date) = weekDays[index]
            Column(Modifier.padding(start = 2.dp, bottom = 12.dp)) {
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Txt(day, 14f, theme.text, FontWeight.SemiBold)
                    Txt("$date", 14f, theme.muted)
                }
                Txt("${items.sumOf { it.kcal }} kcal", 12f, theme.muted)
            }
        },
    ) { meal ->
        val shape = RoundedCornerShape(10.dp)
        Row(
            Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
                .background(theme.card, shape)
                .border(1.dp, theme.cardBorder, shape)
                .clip(shape),
        ) {
            Box(Modifier.width(4.dp).fillMaxHeight().background(mealColors[meal.type]))
            Column(Modifier.padding(horizontal = 10.dp, vertical = 9.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Txt(mealTypes[meal.type], 10f, mealColors[meal.type], FontWeight.Bold)
                Txt(meal.name, 13f, theme.text, FontWeight.Medium)
                Txt("${meal.kcal} kcal", 11f, theme.muted)
            }
        }
    }
}

// ---- Trip planner ------------------------------------------------------------------------------

private class Place(
    val id: Int,
    val title: String,
    val minutes: Int,
    val kind: String,
    val art: Pair<Color, Color>,
    val note: String? = null,
    val booked: Boolean = false,
)

private val tripColumns = listOf("Ideas", "Day 1", "Day 2", "Day 3")
private const val DAY_LIMIT_MINUTES = 8 * 60

private fun shortDuration(m: Int): String = when {
    m < 60 -> "${m}m"
    m % 60 == 0 -> "${m / 60}h"
    else -> "${m / 60}h${m % 60}"
}

private fun fullDuration(m: Int): String = when {
    m < 60 -> "${m}m"
    m % 60 == 0 -> "${m / 60}h"
    else -> "${m / 60}h ${m % 60}m"
}

private val food = Color(0xFFFF8A5B) to Color(0xFFD6336C)
private val sights = Color(0xFF38BDF8) to Color(0xFF4338CA)
private val culture = Color(0xFFC084FC) to Color(0xFF6D28D9)
private val nature = Color(0xFF34D399) to Color(0xFF0F766E)
private val night = Color(0xFF818CF8) to Color(0xFF1E1B4B)

private fun trip(): List<List<Place>> = listOf(
    listOf(
        Place(1, "Pastel de nata tasting", 45, "Food", food),
        Place(2, "Sunset at Miradouro da Graca", 60, "Viewpoint", sights),
        Place(3, "LX Factory market", 120, "Shopping", culture),
        Place(4, "Day trip to Sintra", 300, "Day trip", nature, note = "Leave before 9am to beat the queues"),
        Place(5, "Fado night in Alfama", 120, "Music", night, booked = true),
    ),
    listOf(
        Place(6, "Alfama old town walk", 120, "Walk", sights),
        Place(7, "Lunch at Time Out Market", 75, "Food", food),
        Place(8, "Tram 28 to Estrela", 45, "Ride", culture),
    ),
    listOf(
        Place(9, "Belem Tower", 90, "Sights", sights, booked = true),
        Place(10, "Pasteis de Belem", 45, "Food", food),
        Place(11, "MAAT museum", 120, "Museum", culture, note = "Closes at 7pm"),
    ),
    listOf(
        Place(12, "Beach day in Cascais", 240, "Beach", nature),
        Place(13, "Dinner by the river", 120, "Food", food),
    ),
)

@Composable
internal fun TripPlanner(theme: DemoTheme, modifier: Modifier = Modifier) {
    val state = rememberDragBoardState(trip()) { it.id }
    DragBoard(
        state = state,
        modifier = modifier.fillMaxWidth().height(430.dp),
        columnWidth = 248.dp,
        columnStyle = ColumnStyle(background = theme.column, border = theme.columnBorder, shape = RoundedCornerShape(18.dp)),
        appearance = DragAppearance(cornerRadius = 14.dp, liftScale = 1.05f, placeholderFill = theme.placeholder, placeholderBorder = theme.columnBorder),
        header = { index, places ->
            val total = places.sumOf { it.minutes }
            val over = index > 0 && total > DAY_LIMIT_MINUTES
            Row(
                Modifier.fillMaxWidth().padding(start = 2.dp, end = 2.dp, bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Txt(tripColumns[index], 14f, theme.text, FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                if (index == 0) {
                    Txt("${places.size} ideas", 12f, theme.muted)
                } else {
                    Symbol(Sym.Clock, 12f, if (over) theme.accents[2] else theme.muted)
                    Txt(
                        if (over) "${fullDuration(total)}, too packed" else fullDuration(total),
                        12f,
                        if (over) theme.accents[2] else theme.muted,
                        FontWeight.Medium,
                    )
                }
            }
        },
    ) { place ->
        val shape = RoundedCornerShape(14.dp)
        Row(
            Modifier.fillMaxWidth().background(theme.card, shape).border(1.dp, theme.cardBorder, shape).padding(10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Box(
                Modifier.size(44.dp).clip(RoundedCornerShape(10.dp)).background(Brush.linearGradient(listOf(place.art.first, place.art.second))),
                contentAlignment = Alignment.Center,
            ) { Txt(shortDuration(place.minutes), 12f, Color.White, FontWeight.Bold) }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Txt(place.title, 14f, theme.text, FontWeight.SemiBold)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Txt(place.kind, 12f, theme.muted)
                    if (place.booked) {
                        Box(Modifier.background(theme.accents[0].copy(alpha = 0.16f), CircleShape).padding(horizontal = 6.dp, vertical = 1.dp)) {
                            Txt("Booked", 10f, theme.accents[0], FontWeight.Bold)
                        }
                    }
                }
                place.note?.let { Txt(it, 12f, theme.muted) }
            }
        }
    }
}

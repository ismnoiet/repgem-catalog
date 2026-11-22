//
//  Examples.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Dark-theme demos. Open the project in Android Studio and use the Compose preview
//  (or call `DragableCardsExamples()` from an activity). Add demos by appending a `DemoSection`.
//
package com.repgem.dragablecards.demo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.fillMaxWidth

@Composable
fun DragableCardsExamples(onBack: (() -> Unit)? = null) {
    DemoScreen(title = "Dragable Cards", background = DarkTheme.page, titleColor = DarkTheme.text, onBack = onBack) {
        Column(
            Modifier.fillMaxWidth().padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(30.dp),
        ) {
            Txt("Long-press a card, then drag it anywhere", 12f, DarkTheme.muted)
            DemoSection("Project board", DarkTheme) { ProjectBoard(DarkTheme) }
            DemoSection("Hiring pipeline (reports every move)", DarkTheme) { HiringBoard(DarkTheme) }
            DemoSection("Music queue (live equalizer, live totals)", DarkTheme) { MusicQueue(DarkTheme) }
            DemoSection("Weekly meals (five columns, scrolls as you drag)", DarkTheme) { MealPlanner(DarkTheme) }
            DemoSection("Trip planner (a day turns amber when overbooked)", DarkTheme) { TripPlanner(DarkTheme) }
        }
    }
}

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun DragableCardsExamplesPreview() {
    DragableCardsExamples()
}

//
//  ExamplesLight.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Light-theme demos, same layout as the dark page. Open the project in Android Studio and use the
//  Compose preview (or call `DragableCardsExamplesLight()` from an activity).
//  Add demos by appending a `DemoSection`.
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
fun DragableCardsExamplesLight(onBack: (() -> Unit)? = null) {
    DemoScreen(title = "Dragable Cards", background = LightTheme.page, titleColor = LightTheme.text, onBack = onBack) {
        Column(
            Modifier.fillMaxWidth().padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(30.dp),
        ) {
            Txt("Long-press a card, then drag it anywhere", 12f, LightTheme.muted)
            DemoSection("Project board", LightTheme) { ProjectBoard(LightTheme) }
            DemoSection("Hiring pipeline (reports every move)", LightTheme) { HiringBoard(LightTheme) }
            DemoSection("Music queue (live equalizer, live totals)", LightTheme) { MusicQueue(LightTheme) }
            DemoSection("Weekly meals (five columns, scrolls as you drag)", LightTheme) { MealPlanner(LightTheme) }
            DemoSection("Trip planner (a day turns amber when overbooked)", LightTheme) { TripPlanner(LightTheme) }
        }
    }
}

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun DragableCardsExamplesLightPreview() {
    DragableCardsExamplesLight()
}

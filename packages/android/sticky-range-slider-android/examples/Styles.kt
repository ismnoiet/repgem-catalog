package com.example.app

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.repgem.stickyrangeslider.*

@Composable
fun Styles() {
    var lower by remember { mutableIntStateOf(40) }
    var upper by remember { mutableIntStateOf(140) }
    val onChange = { lo: Int, hi: Int -> lower = lo; upper = hi }

    Column(verticalArrangement = Arrangement.spacedBy(28.dp)) {
        // On a light surface (default) and on a dark one.
        StickyRangeSlider(lower, upper, onChange, bounds = 20..200, style = StickySliderStyle.ink)
        StickyRangeSlider(lower, upper, onChange, bounds = 20..200, style = StickySliderStyle.paper)

        // Any color.
        StickyRangeSlider(lower, upper, onChange, bounds = 20..200, style = StickySliderStyle.accent(Color.Blue))

        // Or build your own.
        val brand = StickySliderStyle(
            pill = Color(0xFF4F46E5), label = Color.White,
            track = Color(0x334F46E5), trackFill = Color(0xFF4F46E5),
            shadow = Color(0x664F46E5),
        )
        StickyRangeSlider(lower, upper, onChange, bounds = 20..200, style = brand)
    }
}

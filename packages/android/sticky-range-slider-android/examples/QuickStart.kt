package com.example.app

import androidx.compose.runtime.*
import com.repgem.stickyrangeslider.*

@Composable
fun PriceFilter() {
    var lower by remember { mutableIntStateOf(85) }
    var upper by remember { mutableIntStateOf(240) }

    StickyRangeSlider(
        lower = lower,
        upper = upper,
        onRangeChange = { lo, hi -> lower = lo; upper = hi },
        bounds = 20..400,
        step = 5,
    )
}

@Composable
fun DistanceFilter() {
    var distance by remember { mutableIntStateOf(12) }

    // One handle, other units.
    StickyRangeSlider(distance, { distance = it }, bounds = 1..50, step = 1, prefix = "", suffix = " km")
}

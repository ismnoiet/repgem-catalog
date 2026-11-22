package com.example.app

import androidx.compose.runtime.*
import com.repgem.stickyrangeslider.*

@Composable
fun Timing() {
    var lower by remember { mutableIntStateOf(85) }
    var upper by remember { mutableIntStateOf(240) }

    // Heavy, lazy handles. Every value is a spring response in seconds.
    StickyRangeSlider(
        lower = lower,
        upper = upper,
        onRangeChange = { lo, hi -> lower = lo; upper = hi },
        timing = StickyTiming(follow = 0.45, glide = 0.6),
        // true when a drag starts, false when it ends
        onEditingChanged = { editing -> if (!editing) println("search $lower..$upper") },
    )
}

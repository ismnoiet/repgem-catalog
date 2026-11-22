//
//  Examples.kt
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
//  Dark-theme demos. Open the project in Android Studio and use the Compose preview
//  (or call `StickyRangeSliderExamples()` from an activity). Add demos by appending a
//  `DemoSection` in `ExampleStack` (DemoSupport.kt).
//
package com.repgem.stickyrangeslider.demo

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun StickyRangeSliderExamples(onBack: (() -> Unit)? = null) {
    val theme = DemoTheme(dark = true)
    DemoScreen(title = "Sticky Range Slider", background = theme.page, titleColor = theme.ink, onBack = onBack) {
        ExampleStack(theme)
    }
}

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun StickyRangeSliderExamplesPreview() {
    StickyRangeSliderExamples()
}

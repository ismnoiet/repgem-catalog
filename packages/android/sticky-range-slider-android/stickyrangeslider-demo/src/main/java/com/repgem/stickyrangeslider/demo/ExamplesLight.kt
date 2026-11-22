//
//  ExamplesLight.kt
//  StickyRangeSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); gooey fuse effect on Android 12+ (API 31)
//
//  Light-theme demos, same layout as the dark ones. Open the project in Android Studio and use
//  the Compose preview (or call `StickyRangeSliderExamplesLight()` from an activity).
//
package com.repgem.stickyrangeslider.demo

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun StickyRangeSliderExamplesLight(onBack: (() -> Unit)? = null) {
    val theme = DemoTheme(dark = false)
    DemoScreen(title = "Sticky Range Slider", background = theme.page, titleColor = theme.ink, onBack = onBack) {
        ExampleStack(theme)
    }
}

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun StickyRangeSliderExamplesLightPreview() {
    StickyRangeSliderExamplesLight()
}

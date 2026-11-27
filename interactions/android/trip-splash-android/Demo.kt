//
//  Demo.kt
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Previews the interaction inside the shared demo frame (title and @repgem). Not needed in your app.
//
package com.repgem.tripsplash

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

@Composable
fun TripSplashDemoScreen() {
    DemoScreen(title = "Trip Splash", background = Color.Black, titleColor = Color.White, scrolls = false) {
        TripSplash()
    }
}

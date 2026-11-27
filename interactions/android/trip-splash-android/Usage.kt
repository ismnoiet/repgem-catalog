// 1. Download TripSplash.kt
// 2. Add it to your app module (Compose, minSdk 24). Change the package line to yours.
// 3. Show it at launch and pass the screen it should reveal. Tap to replay.

@Composable
fun Launch() {
    TripSplash {
        HomeScreen()
    }
}

// No screen yet? This reveals a neutral placeholder.
// TripSplash()

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("maven-publish")
}

android {
    namespace = "com.repgem.dragablecards"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        // Compose compiler 1.5.10 pairs with Kotlin 1.9.22.
        kotlinCompilerExtensionVersion = "1.5.10"
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    // Compose is part of the public API (Modifier, Dp, composable slots), so expose it to consumers.
    api(platform("androidx.compose:compose-bom:2024.02.00"))
    api("androidx.compose.ui:ui")
    api("androidx.compose.foundation:foundation")
    api("androidx.compose.animation:animation-core")

    testImplementation("junit:junit:4.13.2")
}

afterEvaluate {
    publishing {
        publications {
            register<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.github.ismnoiet"   // JitPack-style coordinates
                artifactId = "dragable-cards-android"
                // The version comes from item.json, the single source (the mirror sync tags the repo with the same value).
                version = Regex("\"version\"\\s*:\\s*\"([^\"]+)\"").find(rootProject.file("item.json").readText())?.groupValues?.get(1) ?: error("item.json has no version")
            }
        }
    }
}

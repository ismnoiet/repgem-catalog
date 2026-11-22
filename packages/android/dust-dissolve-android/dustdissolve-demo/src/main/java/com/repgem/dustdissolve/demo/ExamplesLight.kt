//
//  ExamplesLight.kt
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
package com.repgem.dustdissolve.demo

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

/** Same demo, starting in the light theme. */
@Composable
fun DustDissolveExamplesLight(modifier: Modifier = Modifier, onBack: (() -> Unit)? = null) =
    DustDissolveExamples(modifier = modifier, dark = false, onBack = onBack)

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun DustDissolveExamplesLightPreview() = DustDissolveExamplesLight()

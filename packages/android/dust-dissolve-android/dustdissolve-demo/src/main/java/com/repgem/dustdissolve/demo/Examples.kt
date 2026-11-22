//
//  Examples.kt
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
//  One screen that shows the range of DustDissolve. Scroll it and tap things (a coupon, the eye, a bubble).
//  Nothing in the layout moves: a dissolving view keeps its place.
//
//    Coupons            tap a coupon: it shimmers, then flows into the pill
//    Hide balance       the amount turns to dust, dots take its place
//    Hide password      the visible text turns to dust, dots take its place
//    Messages           bubbles blow away toward the side they sit on
//
//  One DustDissolveScope around the whole scroll view draws the dust for all of them.
//
package com.repgem.dustdissolve.demo

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.repgem.dustdissolve.DustDissolveController
import com.repgem.dustdissolve.DustDissolveScope

/** The showcase screen. */
@Composable
fun DustDissolveExamples(modifier: Modifier = Modifier, dark: Boolean = true, onBack: (() -> Unit)? = null) {
    val th = if (dark) Theme.Dark else Theme.Light
    val m = remember { ShowcaseModel() }

    DustDissolveScope(m.all, modifier.fillMaxSize()) {
        DemoScreen(title = "Dust Dissolve", background = th.bg, titleColor = th.fg, onBack = onBack) {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                SectionCard("Coupons", th) {
                    CouponsCard(m.coupons, th)
                }
                BalanceSection(m, th)
                PasswordSection(m, th)
                MessagesSection(m, th)
            }
        }
    }
}

@Preview(widthDp = 390, heightDp = 844)
@Composable
private fun DustDissolveExamplesPreview() = DustDissolveExamples()

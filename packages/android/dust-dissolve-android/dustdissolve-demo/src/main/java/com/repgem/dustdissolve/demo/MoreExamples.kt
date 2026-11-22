//
//  MoreExamples.kt
//  DustDissolveDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
//  The sections of the showcase that need no target: the dust drifts away. In every
//  one of them the dissolving view keeps its place in the layout, so nothing around it moves.
//
package com.repgem.dustdissolve.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.layout.layout
import kotlin.math.roundToInt
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.repgem.dustdissolve.DustDissolveConfiguration
import com.repgem.dustdissolve.DustDissolveController
import com.repgem.dustdissolve.DustDissolveDirection
import com.repgem.dustdissolve.DustDissolveMotion
import com.repgem.dustdissolve.dustSource
import kotlinx.coroutines.delay

// MARK: - Model: every controller of the showcase, so one scope can draw all the dust

/**
 * Folds the slot away (height, or width when [horizontal]) while the child keeps its full size. The dust is
 * born from the child's bounds, so they must not change while it flies; the neighbours just slide in.
 */
@Composable
internal fun Modifier.foldAway(folded: Boolean, horizontal: Boolean = false): Modifier {
    val f by animateFloatAsState(if (folded) 0f else 1f, tween(250), label = "fold")
    return this.layout { measurable, constraints ->
        val p = measurable.measure(constraints)
        val w = if (horizontal) (p.width * f).roundToInt() else p.width
        val h = if (horizontal) p.height else (p.height * f).roundToInt()
        layout(w, h) { p.place(0, 0) }
    }
}

/** The view is fully gone (dissolve finished), so its slot can fold while the dust is still flying. */
@Composable
internal fun rememberGone(dust: DustDissolveController): Boolean {
    val gone by remember(dust) { derivedStateOf { dust.time > dust.configuration.dissolveEnd + 0.05 } }
    return gone
}

internal val DustDissolveController.isIdle get() = time == DustDissolveController.IDLE

internal class ShowcaseModel {
    val coupons = List(2) { i ->
        // The original coupon: shimmer, dissolve, then flow to the target.
        DustDissolveController(DustDissolveConfiguration.Coupon.copy(seed = 7L + i * 13))
    }

    val password = DustDissolveController(
        DustDissolveConfiguration.Dismiss.copy(
            direction = DustDissolveDirection.LeftToRight,
            motion = DustDissolveMotion.Drift(-25f, 90.dp),
            particleCount = 420, dotSizeMin = 1.4f, dotSizeMax = 2.6f, sparkleEvery = 0,
            dissolveStart = 0.0, dissolveEnd = 0.55, flightStart = 0.25, flightStagger = 0.3,
            total = 1.6, seed = 90,
        ),
    )
    var passwordHidden by mutableStateOf(false)

    val balance = DustDissolveController(
        password.configuration.copy(
            particleCount = 520, dotSizeMin = 1.6f, dotSizeMax = 3.0f,
            motion = DustDissolveMotion.Drift(-20f, 110.dp), dissolveEnd = 0.6, seed = 91,
        ),
    )
    var balanceHidden by mutableStateOf(false)

    val messages = List(3) { i ->
        val fromLeft = i % 2 == 0
        DustDissolveController(
            DustDissolveConfiguration.Dismiss.copy(
                direction = if (fromLeft) DustDissolveDirection.RightToLeft else DustDissolveDirection.LeftToRight,
                motion = DustDissolveMotion.Drift(if (fromLeft) 195f else -15f, 130.dp),
                particleCount = 520, seed = 70L + i,
            ),
        )
    }

    val all: List<DustDissolveController> = coupons + listOf(balance, password) + messages

    suspend fun fire(cs: List<DustDissolveController>, everyMs: Long = 140, shuffled: Boolean = false) {
        for (c in if (shuffled) cs.shuffled() else cs) {
            c.fire()
            delay(everyMs)
        }
    }

    fun reset(cs: List<DustDissolveController>) = cs.forEach { it.reset() }

    /** Hide: the visible text turns to dust, then the dots fade in. Show: the text is simply back. */
    fun setPassword(hidden: Boolean) {
        passwordHidden = hidden
        if (hidden) password.fire() else password.reset()
    }

    fun setBalance(hidden: Boolean) {
        balanceHidden = hidden
        if (hidden) balance.fire() else balance.reset()
    }

}

// MARK: - Section chrome

@Composable
internal fun SectionCard(
    title: String,
    th: Theme,
    modifier: Modifier = Modifier,
    padded: Boolean = true,
    content: @Composable () -> Unit,
) {
    val shape = RoundedCornerShape(20.dp)
    Column(modifier.fillMaxWidth().background(th.card, shape).border(1.dp, th.line, shape)) {
        Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Label(title, 14f, FontWeight.SemiBold, th.fg, Modifier.weight(1f))
        }
        Spacer(Modifier.height(14.dp))
        Box(Modifier.fillMaxWidth().padding(horizontal = if (padded) 16.dp else 0.dp).padding(bottom = if (padded) 16.dp else 0.dp)) {
            content()
        }
    }
}

// MARK: - Show / hide balance

@Composable
internal fun BalanceSection(m: ShowcaseModel, th: Theme) {
    val amount = "$12,480.50"
    val dotsAlpha by animateFloatAsState(
        targetValue = if (m.balanceHidden) 1f else 0f,
        animationSpec = tween(300, delayMillis = if (m.balanceHidden) 500 else 0),
        label = "balanceDots",
    )
    SectionCard("Hide balance", th) {
        Row(Modifier.fillMaxWidth().height(64.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Label("Total balance", 12f, FontWeight.Normal, th.sub)
                Spacer(Modifier.height(4.dp))
                Box {
                    Label(amount, 32f, FontWeight.Bold, th.fg, Modifier.dustSource(m.balance))   // ← the amount that dissolves
                    Label("••••••", 32f, FontWeight.Bold, th.fg, Modifier.alpha(dotsAlpha))
                }
            }
            Box(
                Modifier.size(width = 56.dp, height = 40.dp).clip(CircleShape).background(th.fg.copy(alpha = 0.08f))
                    .clickable { m.setBalance(!m.balanceHidden) },
                contentAlignment = Alignment.Center,
            ) { Label(if (m.balanceHidden) "Show" else "Hide", 12f, FontWeight.Medium, th.sub) }
        }
    }
}

// MARK: - Show / hide password

@Composable
internal fun PasswordSection(m: ShowcaseModel, th: Theme) {
    val secret = "hunter2-Mochi!"
    val dotsAlpha by animateFloatAsState(
        targetValue = if (m.passwordHidden) 1f else 0f,
        animationSpec = tween(300, delayMillis = if (m.passwordHidden) 500 else 0),
        label = "dots",
    )
    SectionCard("Hide password", th) {
        Row(
            Modifier.fillMaxWidth().height(52.dp).background(th.fg.copy(alpha = 0.06f), RoundedCornerShape(12.dp)).padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Label("🔒", 14f, FontWeight.Normal, th.sub)
            Box(Modifier.weight(1f)) {
                Label(secret, 17f, FontWeight.Medium, th.fg, Modifier.dustSource(m.password))   // ← the text that dissolves
                Label("•".repeat(secret.length), 17f, FontWeight.Medium, th.fg, Modifier.alpha(dotsAlpha))
            }
            Box(
                Modifier.size(36.dp).clickable { m.setPassword(!m.passwordHidden) },
                contentAlignment = Alignment.Center,
            ) { Label(if (m.passwordHidden) "Show" else "Hide", 12f, FontWeight.Medium, th.sub) }
        }
    }
}

// MARK: - Disappearing messages

@Composable
internal fun MessagesSection(m: ShowcaseModel, th: Theme) {
    val texts = listOf("Are you free tonight?", "Yes! 8pm works", "Perfect, see you then")
    SectionCard("Disappearing messages", th) {
        Column(Modifier.fillMaxWidth()) {
            texts.forEachIndexed { i, text ->
                val dust = m.messages[i]
                val mine = i % 2 == 1
                // as soon as the bubble is gone its slot folds away and the ones below slide up
                Row(
                    Modifier.fillMaxWidth().foldAway(rememberGone(dust)).padding(bottom = 8.dp),
                    horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start,
                ) {
                    Box(
                        Modifier.widthIn(max = 260.dp)
                            .dustSource(dust)
                            .clip(RoundedCornerShape(18.dp))
                            .background(if (mine) Color(0xFF3E63DD) else th.fg.copy(alpha = 0.10f))
                            .clickable { dust.fire() }
                            .padding(horizontal = 14.dp, vertical = 10.dp),
                    ) { Label(text, 13f, FontWeight.Normal, if (mine) Color.White else th.fg) }
                }
            }
        }
    }
}

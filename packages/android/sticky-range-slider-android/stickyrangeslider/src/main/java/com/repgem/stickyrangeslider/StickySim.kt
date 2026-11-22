//
//  StickySim.kt
//  StickyRangeSlider
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
package com.repgem.stickyrangeslider

import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * Per-frame spring simulation for the two handles and the merge amount.
 *
 * A plain class on purpose: it is stepped every frame from a frame loop, and the result is read
 * in the draw and layout phases, so no recomposition happens while it moves.
 */
internal class StickySim {
    var xLo = 0f; var vLo = 0f
    var xHi = 0f; var vHi = 0f
    /** 0 = two pills, 1 = one fused pill. */
    var m = 0f; var vm = 0f

    /** Softer follow spring, used while a tapped handle glides to its new spot. */
    var glide = false

    /** True while the frame loop is alive; lets a restarted loop keep its frame clock. */
    var running = false

    private var lastNanos = 0L
    var primed = false
        private set

    /** Jump straight to the targets (first layout, or Animations off). */
    fun snapTo(tLo: Float, tHi: Float, tM: Float) {
        xLo = tLo; xHi = tHi; m = tM
        vLo = 0f; vHi = 0f; vm = 0f
        primed = true
    }

    /** Call when the frame loop starts again, so the pause isn't counted as one long frame. */
    fun resume() { lastNanos = 0L }

    fun step(nowNanos: Long, tLo: Float, tHi: Float, tM: Float, timing: StickyTiming, instant: Boolean) {
        if (!primed || instant) {
            snapTo(tLo, tHi, tM)
            lastNanos = nowNanos
            return
        }
        val prev = lastNanos
        lastNanos = nowNanos
        if (prev == 0L) return
        val dt = min((nowNanos - prev) / 1_000_000_000f, 1f / 20f)
        if (dt <= 0f) return

        val follow = StickyMath.omega(if (glide) timing.glide else timing.follow)
        val zFollow = if (glide) StickyDamping.GLIDE else StickyDamping.FOLLOW
        val merge = StickyMath.omega(timing.merge)

        // Sub-step so stiff springs stay stable even after a dropped frame.
        val n = max(1, ceil(dt / (1f / 240f)).toInt())
        val h = dt / n
        repeat(n) {
            val a = spring(xLo, vLo, tLo, follow, zFollow, h); xLo = a.first; vLo = a.second
            val b = spring(xHi, vHi, tHi, follow, zFollow, h); xHi = b.first; vHi = b.second
            val c = spring(m, vm, tM, merge, StickyDamping.MERGE, h); m = c.first; vm = c.second
        }
    }

    /** True once everything has come to rest on its target, so the frame loop can stop. */
    fun isSettled(tLo: Float, tHi: Float, tM: Float): Boolean =
        primed &&
            abs(xLo - tLo) < 0.05f && abs(xHi - tHi) < 0.05f && abs(m - tM) < 0.002f &&
            abs(vLo) < 0.5f && abs(vHi) < 0.5f && abs(vm) < 0.02f

    private fun spring(x: Float, v: Float, target: Float, w: Float, z: Float, h: Float): Pair<Float, Float> {
        val a = w * w * (target - x) - 2f * z * w * v
        val nv = v + a * h
        return (x + nv * h) to nv
    }
}

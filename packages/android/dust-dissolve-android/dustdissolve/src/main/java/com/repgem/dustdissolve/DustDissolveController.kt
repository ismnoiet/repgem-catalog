//
//  DustDissolveController.kt
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
package com.repgem.dustdissolve

import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.flow.first

/**
 * Owns one dust-dissolve run. Create it once, call `fire()` when the coupon is applied.
 *
 *     val dust = remember { DustDissolveController() }
 *     dust.fire()      // run the effect
 *     dust.reset()     // back to the intact coupon
 *
 * Host UI that has to move in step with the dust (the price, a banner…) reads [time] in composition
 * (or in a draw / layer lambda, which only invalidates drawing).
 */
@Stable
class DustDissolveController(val configuration: DustDissolveConfiguration = DustDissolveConfiguration()) {

    /** Seconds since `fire()`. [IDLE] before the first run. Past `configuration.total` once finished. */
    var time: Double by mutableDoubleStateOf(IDLE)
        internal set

    /** `true` while the sequence runs (frames are being produced), `false` when idle or finished. */
    var isActive: Boolean by mutableStateOf(false)
        internal set

    internal var runId: Int by mutableIntStateOf(0)

    internal val particles: List<DustParticle> = buildParticles(configuration)

    /** Runs the effect from the start (restarts it if it is already running). */
    fun fire() {
        runId += 1
        time = 0.0
        isActive = true
    }

    /** Puts the coupon back, intact. */
    fun reset() {
        runId += 1
        time = IDLE
        isActive = false
    }

    /** Suspends until the sequence has finished (`isActive` is `false`). */
    suspend fun finished() {
        snapshotFlow { isActive }.first { !it }
    }

    internal fun finish() {
        time = configuration.total + 1
        isActive = false
    }

    companion object {
        /** `time` while nothing has run yet. */
        const val IDLE = -1.0
    }
}

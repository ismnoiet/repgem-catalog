package com.repgem.stickyrangeslider

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class StickyMathTest {

    private val bounds = 20..400

    @Test
    fun snapRoundsToStepAndClamps() {
        assertEquals(185, StickyMath.snap(187.0, 5, bounds))
        assertEquals(190, StickyMath.snap(188.0, 5, bounds))
        assertEquals(20, StickyMath.snap(-50.0, 5, bounds))
        assertEquals(400, StickyMath.snap(9_999.0, 5, bounds))
    }

    @Test
    fun positionAndValueRoundTrip() {
        val width = 300f
        for (v in 20..400 step 20) {
            val x = StickyMath.x(v.toDouble(), width, bounds)
            assertEquals(v.toDouble(), StickyMath.value(x, width, bounds), 0.001)
        }
    }

    @Test
    fun valueClampsOutsideTheTrack() {
        assertEquals(20.0, StickyMath.value(-500f, 300f, bounds), 0.0)
        assertEquals(400.0, StickyMath.value(5_000f, 300f, bounds), 0.0)
    }

    @Test
    fun mergeHasHysteresis() {
        // Apart: stays apart until clearly inside the merge distance.
        assertFalse(StickyMath.merged(false, 52f))
        assertTrue(StickyMath.merged(false, 40f))
        // Fused: stays fused until clearly outside the split distance.
        assertTrue(StickyMath.merged(true, 52f))
        assertFalse(StickyMath.merged(true, 60f))
    }

    @Test
    fun pillWidthGrowsWithText() {
        assertTrue(StickyMath.pillWidth("\$85") < StickyMath.pillWidth("\$185"))
        assertEquals(4 * 7.2f + 20f, StickyMath.pillWidth("\$185"), 0.01f)
    }

    @Test
    fun simSettlesOnItsTargets() {
        val sim = StickySim()
        sim.snapTo(50f, 200f, 0f)
        var now = 1_000_000_000L
        sim.resume()
        repeat(120) {                                   // 2 s at 60 fps
            now += 16_666_667L
            sim.step(now, 120f, 200f, 1f, StickyTiming(), instant = false)
        }
        assertTrue(sim.isSettled(120f, 200f, 1f))
    }

    @Test
    fun animationsOffJumpsToTargets() {
        val sim = StickySim()
        sim.snapTo(50f, 200f, 0f)
        sim.step(1_000_000_000L, 120f, 220f, 1f, StickyTiming(), instant = true)
        assertEquals(120f, sim.xLo, 0f)
        assertEquals(220f, sim.xHi, 0f)
        assertEquals(1f, sim.m, 0f)
    }
}

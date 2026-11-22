package com.repgem.dustdissolve

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pure configuration tests: no rendering, no shader. Mirrors DustDissolveConfigurationTests.swift on iOS. */
class DustDissolveConfigurationTest {

    @Test
    fun defaultsMatchTheCouponRecording() {
        val c = DustDissolveConfiguration()
        assertTrue(c.shimmer)
        assertEquals(0.55, c.dissolveStart, 0.0)
        assertEquals(1.10, c.dissolveEnd, 0.0)
        assertEquals(3.0, c.total, 0.0)
        assertEquals(1100, c.particleCount)
    }

    @Test
    fun arrivalIsWhenTheFirstDotLands() {
        val c = DustDissolveConfiguration()
        assertEquals(c.flightStart + 0.8, c.arrival, 0.0001)
    }

    @Test
    fun pastelPaletteHasSixColors() {
        assertEquals(6, DustDissolvePalette.Pastel.size)
        assertEquals(6, DustDissolveConfiguration().palette.size)
    }

    @Test
    fun presetsTurnTheShimmerOffExceptCoupon() {
        assertTrue(DustDissolveConfiguration.Coupon.shimmer)
        for (c in listOf(DustDissolveConfiguration.Snap, DustDissolveConfiguration.Dismiss, DustDissolveConfiguration.Fall, DustDissolveConfiguration.Burst))
            assertFalse(c.shimmer)
    }

    @Test
    fun fallGoesTopToBottomAndBurstIsRoundFromTheCentre() {
        assertEquals(DustDissolveDirection.TopToBottom, DustDissolveConfiguration.Fall.direction)
        assertEquals(DustDissolveDirection.CenterOut, DustDissolveConfiguration.Burst.direction)
        assertEquals(DustDissolveShape.Ellipse, DustDissolveConfiguration.Burst.shape)
    }

    @Test
    fun everyPresetEndsAfterItsDustHasLeft() {
        val all = listOf(
            DustDissolveConfiguration.Coupon, DustDissolveConfiguration.Snap, DustDissolveConfiguration.Dismiss,
            DustDissolveConfiguration.Fall, DustDissolveConfiguration.Burst,
        )
        for (c in all) {
            assertTrue(c.total > c.dissolveEnd)
            assertTrue(c.total >= c.flightStart)
        }
    }

    @Test
    fun copyKeepsTheRestOfAPreset() {
        val c = DustDissolveConfiguration.Fall.copy(particleCount = 700, seed = 3)
        assertEquals(700, c.particleCount)
        assertEquals(DustDissolveDirection.TopToBottom, c.direction)
        assertFalse(c.shimmer)
    }
}

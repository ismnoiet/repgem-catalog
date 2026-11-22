package com.repgem.dragablecards

import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DragConfigurationTest {

    @Test
    fun defaultTimingFeelsSnappy() {
        val t = DragTiming()
        assertEquals(150L, t.longPressMillis)
        assertTrue("lift should be a quick spring", t.lift.stiffness >= 800f)
        assertTrue("shuffle should settle fast", t.shuffle.stiffness >= 600f)
    }

    @Test
    fun dropSpringDoesNotOvershoot() {
        // A damping ratio of 1 or more is critically damped (or over): the card can't wobble in its slot.
        assertTrue(DragTiming().drop.dampingRatio >= 1f)
    }

    @Test
    fun liftedCardIsOnlySlightlyLarger() {
        val a = DragAppearance()
        assertTrue(a.liftScale in 1f..1.1f)
        assertTrue(a.liftTilt in 0f..10f)
        assertTrue(a.liftShadow > 0.dp)
    }

    @Test
    fun settingsCanBeCopiedAndChanged() {
        val t = DragTiming().copy(longPressMillis = 300L)
        assertEquals(300L, t.longPressMillis)
        assertEquals(DragTiming().drop, t.drop)
        assertEquals(8.dp, DragAppearance().copy(cornerRadius = 8.dp).cornerRadius)
    }
}

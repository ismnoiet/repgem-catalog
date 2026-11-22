package com.repgem.dragablecards

import androidx.compose.ui.geometry.Offset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

/** State behaviour that doesn't need a screen: lists, and gestures arriving before anything is laid out. */
class DragBoardStateTest {

    private class Card(val id: Int)

    private fun state() = DragBoardState(
        listOf(listOf(Card(1), Card(2)), listOf(Card(3)), emptyList()),
    ) { it.id }

    @Test
    fun exposesTheInitialColumns() {
        val s = state()
        assertEquals(listOf(listOf(1, 2), listOf(3), emptyList<Int>()), s.columns.map { c -> c.map { it.id } })
        assertFalse(s.isDragging)
    }

    @Test
    fun updateColumnsReplacesTheLists() {
        val s = state()
        s.updateColumns(listOf(listOf(Card(9)), emptyList()))
        assertEquals(listOf(listOf(9), emptyList<Int>()), s.columns.map { c -> c.map { it.id } })
    }

    @Test
    fun nothingIsUnderTheFingerBeforeLayout() {
        assertNull(state().cardAt(Offset(10f, 10f)))
    }

    @Test
    fun startingADragBeforeLayoutIsIgnored() {
        val s = state()
        s.onDragStart(s.columns[0][0], Offset(10f, 10f))
        assertFalse(s.isDragging)
    }

    @Test
    fun movingOrDroppingWithoutADragDoesNothing() {
        val s = state()
        s.onDragMove(Offset(50f, 50f))
        s.onDrop()
        assertFalse(s.isDragging)
        assertEquals(listOf(1, 2), s.columns[0].map { it.id })
    }
}

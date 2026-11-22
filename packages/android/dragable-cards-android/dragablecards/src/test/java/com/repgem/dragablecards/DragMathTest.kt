package com.repgem.dragablecards

import org.junit.Assert.assertEquals
import org.junit.Test

class DragMathTest {

    @Test
    fun insertionIndexCountsCardsAboveTheFinger() {
        val mids = listOf(40f, 120f, 200f)
        assertEquals(0, insertionIndex(10f, mids))
        assertEquals(1, insertionIndex(100f, mids))
        assertEquals(2, insertionIndex(150f, mids))
        assertEquals(3, insertionIndex(900f, mids))
        assertEquals(0, insertionIndex(100f, emptyList()))
    }

    @Test
    fun nearestColumnHasNoDeadZones() {
        val ranges = listOf(16f..296f, 308f..588f, 600f..880f)
        assertEquals(0, nearestColumn(100f, ranges, fallback = 2))   // inside
        assertEquals(1, nearestColumn(304f, ranges, fallback = 0))   // gap, closer to column 1
        assertEquals(0, nearestColumn(-50f, ranges, fallback = 2))   // off the left edge
        assertEquals(2, nearestColumn(2000f, ranges, fallback = 0))  // off the right edge
    }

    @Test
    fun nearestColumnSkipsUnknownColumns() {
        assertEquals(1, nearestColumn(10f, listOf(null, 100f..200f), fallback = 0))
        assertEquals(3, nearestColumn(10f, listOf(null, null), fallback = 3))
    }

    private val key: (String) -> Any = { it }
    private val board = listOf(listOf("a", "b", "c"), listOf("d"), emptyList<String>())

    @Test
    fun moveWithinAColumn() {
        // "a" dropped after "b": index counts the column without the moved card
        assertEquals(listOf(listOf("b", "a", "c"), listOf("d"), emptyList()), moveItem(board, key, "a", 0, 1))
        assertEquals(listOf(listOf("b", "c", "a"), listOf("d"), emptyList()), moveItem(board, key, "a", 0, 2))
        assertEquals(board, moveItem(board, key, "a", 0, 0))
    }

    @Test
    fun moveToAnotherColumn() {
        assertEquals(listOf(listOf("a", "c"), listOf("b", "d"), emptyList()), moveItem(board, key, "b", 1, 0))
        assertEquals(listOf(listOf("a", "b"), listOf("d"), listOf("c")), moveItem(board, key, "c", 2, 0))
    }

    @Test
    fun indexIsClampedAndUnknownKeysAreIgnored() {
        assertEquals(listOf(listOf("b", "c"), listOf("d", "a"), emptyList()), moveItem(board, key, "a", 1, 99))
        assertEquals(board, moveItem(board, key, "zzz", 1, 0))
        assertEquals(board, moveItem(board, key, "a", 7, 0))
    }

    // ---- slot placement in the row list ------------------------------------------------------

    @Test
    fun slotStaysWhereTheDraggedCardWas() {
        // "b" (index 1) is lifted and hasn't moved yet: the slot sits right after it, before "c".
        val items = listOf("a", "b", "c")
        assertEquals(2, slotRowIndex(items, key, "b", targetIndex = 1))
    }

    @Test
    fun slotGoesInFrontOfTheTargetCard() {
        val items = listOf("a", "b", "c", "d")
        assertEquals(0, slotRowIndex(items, key, "c", targetIndex = 0))   // above "a"
        assertEquals(1, slotRowIndex(items, key, "c", targetIndex = 1))   // above "b"
        assertEquals(3, slotRowIndex(items, key, "c", targetIndex = 2))   // above "d" (skips the lifted "c")
        assertEquals(4, slotRowIndex(items, key, "c", targetIndex = 3))   // at the end
    }

    @Test
    fun slotInAnotherColumnIgnoresTheDraggedKey() {
        val items = listOf("d", "e")
        assertEquals(0, slotRowIndex(items, key, "a", targetIndex = 0))
        assertEquals(1, slotRowIndex(items, key, "a", targetIndex = 1))
        assertEquals(2, slotRowIndex(items, key, "a", targetIndex = 2))
        assertEquals(0, slotRowIndex(emptyList(), key, "a", targetIndex = 0))
    }

    // ---- regression: moving up and moving down must trigger at the same overlap ---------------

    /** Card height + gap = 100, first card's centre at 50: centres sit at 50, 150, 250, ... */
    private fun mids(count: Int) = List(count) { 50f + it * 100f }

    @Test
    fun movingUpAndDownSwapAtTheSameDistance() {
        // Four cards, "c" (index 2, centre 250) is dragged. The others sit at 50, 150, 350.
        val others = listOf(50f, 150f, 350f)
        val up = (250 downTo 0).first { insertionIndex(it.toFloat(), others) < 2 }.toFloat()       // first y that swaps up
        val down = (250..500).first { insertionIndex(it.toFloat(), others) > 2 }.toFloat()         // first y that swaps down
        assertEquals(250f - 150f, 250f - up, 1f)    // crosses the card above at 100 px
        assertEquals(350f - 250f, down - 250f, 1f)  // crosses the card below at 100 px
    }

    @Test
    fun walkingAcrossAColumnVisitsEverySlotInOrder() {
        val others = mids(5)
        val up = (500 downTo 0 step 10).map { insertionIndex(it.toFloat(), others) }
        val down = (0..500 step 10).map { insertionIndex(it.toFloat(), others) }
        assertEquals(up.reversed(), down)                           // symmetric
        assertEquals((0..5).toList(), down.distinct())              // no slot is skipped
        assertEquals(down.sorted(), down)                           // never goes backwards
    }

    @Test
    fun movingNeverLosesOrDuplicatesCards() {
        var current = board
        // a long random-looking walk through every column and slot
        val steps = listOf("a" to (2 to 0), "d" to (0 to 3), "b" to (2 to 1), "a" to (1 to 0), "c" to (0 to 0), "d" to (2 to 2))
        for ((k, target) in steps) {
            current = moveItem(current, key, k, target.first, target.second)
            assertEquals(listOf("a", "b", "c", "d"), current.flatten().sorted())
        }
    }

    @Test
    fun movingToTheSamePlaceChangesNothing() {
        assertEquals(board, moveItem(board, key, "b", 0, 1))
        assertEquals(board, moveItem(board, key, "d", 1, 0))
    }
}

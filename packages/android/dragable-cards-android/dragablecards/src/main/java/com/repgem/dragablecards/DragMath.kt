//
//  DragMath.kt
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  The pure, UI-free parts of the interaction (which column, which slot, how a move changes the
//  lists), kept separate so they can be unit tested.
//
package com.repgem.dragablecards

/** Slot for a finger at [pointerY]: the number of other cards whose vertical centre is above it. */
internal fun insertionIndex(pointerY: Float, midYs: List<Float>): Int = midYs.count { it < pointerY }

/**
 * The column nearest to [x]. [ranges] holds each column's left..right (null when unknown). There are
 * no dead zones: a finger in the gap between two columns still picks the closer one.
 */
internal fun nearestColumn(x: Float, ranges: List<ClosedFloatingPointRange<Float>?>, fallback: Int): Int {
    var best = Float.MAX_VALUE
    var index = fallback
    ranges.forEachIndexed { i, r ->
        if (r == null) return@forEachIndexed
        val d = maxOf(r.start - x, 0f, x - r.endInclusive)
        if (d < best) {
            best = d
            index = i
        }
    }
    return index
}

/**
 * Moves the item with [key] to [toIndex] of column [toColumn]. [toIndex] counts the items of the
 * target column without the moved one, and is clamped to the column's size.
 */
internal fun <T> moveItem(
    columns: List<List<T>>,
    itemKey: (T) -> Any,
    key: Any,
    toColumn: Int,
    toIndex: Int,
): List<List<T>> {
    var moved: T? = null
    var found = false
    val without = columns.map { column ->
        column.filter {
            val match = itemKey(it) == key
            if (match) {
                moved = it
                found = true
            }
            !match
        }
    }
    if (!found || toColumn !in columns.indices) return columns
    @Suppress("UNCHECKED_CAST")
    val item = moved as T
    return without.mapIndexed { i, column ->
        if (i != toColumn) column
        else column.toMutableList().apply { add(toIndex.coerceIn(0, size), item) }
    }
}

/**
 * Where the empty slot goes in a column's row list. The list holds every card, including the dragged
 * one (kept in place, collapsed to zero height). [targetIndex] counts the cards without the dragged
 * one, so the slot goes in front of the [targetIndex]-th other card, or at the end.
 */
internal fun <T> slotRowIndex(items: List<T>, itemKey: (T) -> Any, draggedKey: Any, targetIndex: Int): Int {
    val others = items.indices.filter { itemKey(items[it]) != draggedKey }
    return if (targetIndex >= others.size) items.size else others[targetIndex.coerceAtLeast(0)]
}

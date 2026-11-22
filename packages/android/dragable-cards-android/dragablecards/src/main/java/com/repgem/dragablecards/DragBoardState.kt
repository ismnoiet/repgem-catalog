//
//  DragBoardState.kt
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Owns the lists and the whole drag: lift, hover (which column / slot), auto-scroll and the drop.
//  The finger-follow position is only read in layout/draw lambdas, so dragging never recomposes
//  the board: only the floating card moves.
//
package com.repgem.dragablecards

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ScrollState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

/** Creates and remembers a [DragBoardState]. [itemKey] must return a stable, unique key per item. */
@Composable
fun <T : Any> rememberDragBoardState(
    initialColumns: List<List<T>>,
    itemKey: (T) -> Any,
): DragBoardState<T> = remember { DragBoardState(initialColumns, itemKey) }

/**
 * State of a [DragBoard]: the cards of every column, in order. Read [columns] to persist or
 * display them; change them with [updateColumns].
 */
@Stable
class DragBoardState<T : Any>(
    initialColumns: List<List<T>>,
    internal val itemKey: (T) -> Any,
) {
    /** The cards of each column, top to bottom. */
    var columns: List<List<T>> by mutableStateOf(initialColumns)
        private set

    /** True from the moment a card lifts until it has settled in its slot. */
    val isDragging: Boolean get() = dragging != null

    /** Replaces every column (ignored while a card is being dragged). */
    fun updateColumns(columns: List<List<T>>) {
        if (!isDragging) this.columns = columns
    }

    // ---- drag state (structural: changes a few times per drag) -------------------------------

    internal var dragging by mutableStateOf<T?>(null)
    internal var targetColumn by mutableIntStateOf(0)
    internal var targetIndex by mutableIntStateOf(0)
    internal var isDropping by mutableStateOf(false)
    internal var cardSize by mutableStateOf(IntSize.Zero)

    // ---- per-frame state (read only in layout / draw lambdas) --------------------------------

    internal var dragCenter by mutableStateOf(Offset.Zero)
    internal val lift = Animatable(0f)
    internal val landing = Animatable(Offset.Zero, Offset.VectorConverter)
    internal val scroll = ScrollState(0)

    // ---- set by DragBoard each composition ---------------------------------------------------

    internal var scope: CoroutineScope? = null
    internal var density: Density = Density(1f)
    internal var haptics: HapticFeedback? = null
    internal var timing: DragTiming = DragTiming()
    internal var onMove: ((T, Int, Int, Int) -> Unit)? = null

    // ---- layout registry (live coordinates, not snapshot state) ------------------------------

    internal var board: LayoutCoordinates? = null
    /** Where each card is laid out (ignores its in-flight shuffle animation). */
    internal val slotCoords = HashMap<Any, LayoutCoordinates>()
    internal val columnCoords = HashMap<Int, LayoutCoordinates>()
    internal var placeholderCoords: LayoutCoordinates? = null

    private var grab = Offset.Zero
    private var sourceColumn = 0
    private var lastEdgeScroll = 0L

    internal fun keyOf(item: T): Any = itemKey(item)

    // ---- gesture entry points ----------------------------------------------------------------

    internal fun onDragStart(item: T, pointer: Offset) {
        if (dragging != null) return
        val key = keyOf(item)
        val (col, idx) = locate(key) ?: return
        val rect = rectOf(slotCoords[key]) ?: return

        cardSize = IntSize(rect.width.roundToInt(), rect.height.roundToInt())
        grab = pointer - rect.center
        dragCenter = rect.center
        sourceColumn = col
        targetColumn = col
        targetIndex = idx
        haptics?.performHapticFeedback(HapticFeedbackType.LongPress)
        dragging = item
        scope?.launch { lift.animateTo(1f, timing.lift.floatSpec()) }
    }

    /** [pointer] is the finger position in board coordinates. */
    internal fun onDragMove(pointer: Offset) {
        val item = dragging ?: return
        dragCenter = pointer - grab
        val key = keyOf(item)

        // Judge the slot by the dragged card's centre, not by the finger. Where you grabbed the card
        // (top, middle, bottom) then doesn't matter, so moving up and moving down trigger at the
        // same overlap. Using the finger made the slot jump early in one direction.
        val center = dragCenter

        val col = nearestColumn(
            center.x,
            columns.indices.map { i -> rectOf(columnCoords[i])?.let { it.left..it.right } },
            targetColumn,
        )
        val mids = columns[col].filter { keyOf(it) != key }
            .map { rectOf(slotCoords[keyOf(it)])?.center?.y ?: Float.MAX_VALUE }
        val idx = insertionIndex(center.y, mids)

        if (col != targetColumn) revealColumn(col)
        if (col != targetColumn || idx != targetIndex) {
            haptics?.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            targetColumn = col
            targetIndex = idx
        }
        edgeScroll(pointer)
    }

    internal fun onDrop() {
        val item = dragging ?: return
        if (isDropping) return
        haptics?.performHapticFeedback(HapticFeedbackType.TextHandleMove)

        // Hand off: the card moves into its slot, offset to exactly where the floating card is,
        // then one spring brings offset, tilt, scale and shadow to rest. The card lives in the
        // layout while it lands, so scrolling or neighbours settling can't desync it.
        val slot = rectOf(placeholderCoords)
        val start = if (slot != null) dragCenter - slot.center else Offset.Zero
        scope?.launch {
            landing.snapTo(start)
            isDropping = true
            coroutineScope {
                launch { landing.animateTo(Offset.Zero, timing.drop.offsetSpec()) }
                launch { lift.animateTo(0f, timing.drop.floatSpec()) }
            }
            commit(item)
        }
    }

    // ---- internals ---------------------------------------------------------------------------

    private fun commit(item: T) {
        val from = sourceColumn
        val to = targetColumn
        val next = moveItem(columns, itemKey, keyOf(item), to, targetIndex)
        val landed = next[to].indexOfFirst { keyOf(it) == keyOf(item) }
        columns = next
        dragging = null
        isDropping = false
        onMove?.invoke(item, from, to, landed)
    }

    private fun locate(key: Any): Pair<Int, Int>? {
        columns.forEachIndexed { c, items ->
            val i = items.indexOfFirst { keyOf(it) == key }
            if (i >= 0) return c to i
        }
        return null
    }

    private fun rectOf(coords: LayoutCoordinates?): Rect? {
        val b = board ?: return null
        if (coords == null || !coords.isAttached || !b.isAttached) return null
        return b.localBoundingBoxOf(coords, clipBounds = false)
    }

    /** The card under [point] (board coordinates), or null. */
    internal fun cardAt(point: Offset): T? {
        for (items in columns) {
            for (item in items) {
                val r = rectOf(slotCoords[keyOf(item)]) ?: continue
                if (r.contains(point)) return item
            }
        }
        return null
    }

    /** Scrolls the board so [col] is fully visible. */
    private fun revealColumn(col: Int) {
        val r = rectOf(columnCoords[col]) ?: return
        val width = board?.size?.width?.toFloat() ?: return
        val inset = with(density) { 16.dp.toPx() }
        val delta = when {
            r.left < inset -> r.left - inset
            r.right > width - inset -> r.right - (width - inset)
            else -> return
        }
        lastEdgeScroll = System.currentTimeMillis()
        scope?.launch { scroll.animateScrollTo((scroll.value + delta).roundToInt(), tween(350)) }
    }

    /** Near the left/right edge, bring the neighbouring column into view. */
    private fun edgeScroll(pointer: Offset) {
        if (System.currentTimeMillis() - lastEdgeScroll < timing.edgeScrollDelayMillis) return
        val width = board?.size?.width?.toFloat() ?: return
        val edge = with(density) { 56.dp.toPx() }
        if (pointer.x < edge && targetColumn > 0) revealColumn(targetColumn - 1)
        else if (pointer.x > width - edge && targetColumn < columns.size - 1) revealColumn(targetColumn + 1)
    }
}

private fun DragSpring.floatSpec() = spring<Float>(dampingRatio, stiffness)
private fun DragSpring.offsetSpec() = spring(dampingRatio, stiffness, Offset.VisibilityThreshold)

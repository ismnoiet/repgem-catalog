//
//  DragBoard.kt
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  A Trello-style board for Jetpack Compose: columns of cards you can long-press, lift and drag
//  between columns. You bring the card (and optionally the column header); this brings the motion.
//
package com.repgem.dragablecards

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.awaitLongPressOrCancellation
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.GraphicsLayerScope
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.platform.ViewConfiguration
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import kotlin.math.roundToInt

/**
 * A board of columns whose cards can be dragged between (and within) columns.
 *
 * Long-press a card to lift it, drag it over any column and release: the other cards slide out of
 * the way, a slot opens where it will land, and the card snaps into it.
 *
 * @param state the cards of every column; create it with [rememberDragBoardState].
 * @param columnWidth width of each column.
 * @param cardSpacing vertical gap between cards.
 * @param columnStyle the container around each column.
 * @param appearance how the lifted card and the empty slot look.
 * @param timing long-press delay and springs.
 * @param onMove called after a card has landed: the item, its old column, its new column and its
 *   index there.
 * @param placeholder the empty slot shown where the card will land, given the card's height.
 * @param header drawn at the top of each column, above its cards.
 * @param card draws one card. It is also used for the floating copy while dragging.
 */
@Composable
fun <T : Any> DragBoard(
    state: DragBoardState<T>,
    modifier: Modifier = Modifier,
    columnWidth: Dp = 280.dp,
    columnSpacing: Dp = 12.dp,
    cardSpacing: Dp = 8.dp,
    contentPadding: PaddingValues = PaddingValues(16.dp),
    columnStyle: ColumnStyle = ColumnStyle(),
    appearance: DragAppearance = DragAppearance(),
    timing: DragTiming = DragTiming(),
    onMove: ((item: T, fromColumn: Int, toColumn: Int, toIndex: Int) -> Unit)? = null,
    placeholder: @Composable (height: Dp) -> Unit = { DragPlaceholder(it, appearance) },
    header: @Composable (columnIndex: Int, items: List<T>) -> Unit = { _, _ -> },
    card: @Composable (item: T) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current
    val haptics = LocalHapticFeedback.current
    SideEffect {
        state.scope = scope
        state.density = density
        state.haptics = haptics
        state.timing = timing
        state.onMove = onMove
    }

    // The long-press delay is read from the view configuration, so override it for the board.
    val base = LocalViewConfiguration.current
    val viewConfiguration = remember(base, timing.longPressMillis) {
        object : ViewConfiguration by base {
            override val longPressTimeoutMillis: Long get() = timing.longPressMillis
        }
    }

    CompositionLocalProvider(LocalViewConfiguration provides viewConfiguration) {
        Box(
            modifier
                .onGloballyPositioned { state.board = it }
                // The gesture lives on the board, which never moves. Reading the finger through the
                // card you hold doesn't work: that card shifts in the layout when the slot opens
                // above it, which made the floating card jump.
                .pointerInput(state) {
                    awaitEachGesture {
                        val down = awaitFirstDown(requireUnconsumed = false)
                        val item = state.cardAt(down.position) ?: return@awaitEachGesture
                        val press = awaitLongPressOrCancellation(down.id) ?: return@awaitEachGesture
                        state.onDragStart(item, press.position)
                        press.consume()
                        // Initial pass: consume first so the board's own horizontal scroll never sees it.
                        while (true) {
                            val event = awaitPointerEvent(PointerEventPass.Initial)
                            val change = event.changes.firstOrNull { it.id == down.id } ?: break
                            change.consume()
                            if (!change.pressed) break
                            state.onDragMove(change.position)
                        }
                        state.onDrop()
                    }
                },
        ) {
            Row(
                Modifier
                    .fillMaxHeight()
                    .horizontalScroll(state.scroll, enabled = !state.isDragging)
                    .padding(contentPadding),
                horizontalArrangement = Arrangement.spacedBy(columnSpacing),
            ) {
                state.columns.forEachIndexed { index, items ->
                    BoardColumn(
                        state = state,
                        index = index,
                        items = items,
                        columnWidth = columnWidth,
                        cardSpacing = cardSpacing,
                        columnStyle = columnStyle,
                        appearance = appearance,
                        timing = timing,
                        placeholder = placeholder,
                        header = header,
                        card = card,
                    )
                }
            }
            DragOverlay(state, appearance, card)
        }
    }
}

/** The default empty slot: a soft rounded rectangle with a dashed outline. */
@Composable
fun DragPlaceholder(height: Dp, appearance: DragAppearance = DragAppearance()) {
    val shape = RoundedCornerShape(appearance.cornerRadius)
    Box(
        Modifier
            .fillMaxWidth()
            .height(height)
            .background(appearance.placeholderFill, shape)
            .drawBehind {
                drawRoundRect(
                    color = appearance.placeholderBorder,
                    cornerRadius = CornerRadius(appearance.cornerRadius.toPx()),
                    style = Stroke(
                        width = 1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 3.dp.toPx())),
                    ),
                )
            },
    )
}

// ---- rows -------------------------------------------------------------------------------------

private sealed interface BoardRow<out T> {
    class Item<T>(val item: T, val key: Any) : BoardRow<T>
    data object Slot : BoardRow<Nothing>
}

private object SlotKey

@Composable
private fun <T : Any> BoardColumn(
    state: DragBoardState<T>,
    index: Int,
    items: List<T>,
    columnWidth: Dp,
    cardSpacing: Dp,
    columnStyle: ColumnStyle,
    appearance: DragAppearance,
    timing: DragTiming,
    placeholder: @Composable (height: Dp) -> Unit,
    header: @Composable (columnIndex: Int, items: List<T>) -> Unit,
    card: @Composable (item: T) -> Unit,
) {
    val dragged = state.dragging
    val density = LocalDensity.current

    // The column's cards, plus the empty slot at the hovered position. The dragged card itself
    // stays in its source column (collapsed to zero height) so its gesture keeps running.
    val rows = items.map { BoardRow.Item(it, state.keyOf(it)) as BoardRow<T> }.toMutableList()
    if (dragged != null && state.targetColumn == index) {
        rows.add(slotRowIndex(items, state.itemKey, state.keyOf(dragged), state.targetIndex), BoardRow.Slot)
    }

    Column(
        Modifier
            .width(columnWidth)
            .fillMaxHeight()
            .zIndex(if (dragged != null && state.targetColumn == index) 1f else 0f)
            .onGloballyPositioned { state.columnCoords[index] = it }
            .background(columnStyle.background, columnStyle.shape)
            .border(1.dp, columnStyle.border, columnStyle.shape)
            .padding(columnStyle.padding),
    ) {
        header(index, items)
        Column(Modifier.fillMaxWidth()) {
            for (row in rows) {
                when (row) {
                    is BoardRow.Item -> key(row.key) {
                        CardRow(state, row, dragged != null && state.keyOf(dragged) == row.key, cardSpacing, timing, card)
                    }

                    BoardRow.Slot -> key(SlotKey) {
                        SlotRow(state, cardSpacing, appearance, timing, placeholder, card, density.run { state.cardSize.height.toDp() })
                    }
                }
            }
        }
    }
}

@Composable
private fun <T : Any> CardRow(
    state: DragBoardState<T>,
    row: BoardRow.Item<T>,
    isSource: Boolean,
    cardSpacing: Dp,
    timing: DragTiming,
    card: @Composable (item: T) -> Unit,
) {
    val key = row.key
    Box(
        Modifier
            .padding(bottom = if (isSource) 0.dp else cardSpacing)
            .animatePlacement(timing.shuffle) { state.slotCoords[key] = it }
            .collapsed(isSource),
    ) {
        card(row.item)
    }
}

/**
 * The slot where the dragged card will land. While the card hovers it shows [placeholder]; once it
 * is released the card itself is drawn here, offset to where the finger left it, and springs to rest.
 */
@Composable
private fun <T : Any> SlotRow(
    state: DragBoardState<T>,
    cardSpacing: Dp,
    appearance: DragAppearance,
    timing: DragTiming,
    placeholder: @Composable (height: Dp) -> Unit,
    card: @Composable (item: T) -> Unit,
    cardHeight: Dp,
) {
    val dragged = state.dragging
    Box(
        Modifier
            .zIndex(if (state.isDropping) 2f else 0f)
            .padding(bottom = cardSpacing)
            .animatePlacement(timing.shuffle) { state.placeholderCoords = it },
    ) {
        if (state.isDropping && dragged != null) {
            Box(Modifier.graphicsLayer { applyLift(state, appearance, withLanding = true) }) { card(dragged) }
        } else {
            placeholder(cardHeight)
        }
    }
}

/** The card that follows the finger. It is drawn above everything, in board coordinates. */
@Composable
private fun <T : Any> DragOverlay(
    state: DragBoardState<T>,
    appearance: DragAppearance,
    card: @Composable (item: T) -> Unit,
) {
    val item = state.dragging
    if (item == null || state.isDropping) return
    val widthDp = with(LocalDensity.current) { state.cardSize.width.toDp() }
    Box(
        Modifier
            .width(widthDp)
            .offset {
                IntOffset(
                    (state.dragCenter.x - state.cardSize.width / 2f).roundToInt(),
                    (state.dragCenter.y - state.cardSize.height / 2f).roundToInt(),
                )
            }
            .graphicsLayer { applyLift(state, appearance, withLanding = false) },
    ) {
        card(item)
    }
}

/** Scale, tilt and shadow of a lifted card, driven by the lift progress (0 = resting, 1 = lifted). */
private fun GraphicsLayerScope.applyLift(
    state: DragBoardState<*>,
    appearance: DragAppearance,
    withLanding: Boolean,
) {
    val p = state.lift.value
    if (withLanding) {
        translationX = state.landing.value.x
        translationY = state.landing.value.y
    }
    scaleX = 1f + (appearance.liftScale - 1f) * p
    scaleY = scaleX
    rotationZ = appearance.liftTilt * p
    shadowElevation = appearance.liftShadow.toPx() * p
    shape = RoundedCornerShape(appearance.cornerRadius)
    clip = false
}

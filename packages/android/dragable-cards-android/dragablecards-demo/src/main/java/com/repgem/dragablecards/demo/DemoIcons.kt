//
//  DemoIcons.kt
//  DragableCardsDemo
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24)
//
//  Small stroke icons for the demo cards (issue, check, flag, clock, …).
//  Each one is plain SVG path data on a 24 x 24 grid, drawn with a rounded stroke, so the demo
//  needs no icon library and the glyphs scale and tint like text.
//
package com.repgem.dragablecards.demo

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.unit.dp

/** One SVG path. `fill` paints it solid; `cut` draws it in the cut-out color (for "filled" symbols). */
internal class Part(val d: String, val fill: Boolean = false, val cut: Boolean = false)

/** The symbols used by the demos. */
internal enum class Sym(vararg val parts: Part) {
    IssueOpen(
        Part("M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z"),
        Part("M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z", fill = true),
    ),
    CheckCircle(
        Part("M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z"),
        Part("M8 12.5l3 3 5-6"),
    ),
    Ellipsis(
        Part("M5 10.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z", fill = true),
        Part("M12 10.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z", fill = true),
        Part("M19 10.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z", fill = true),
    ),
    Plus(Part("M12 4v16"), Part("M4 12h16")),
    Flag(Part("M5 21V4"), Part("M5 4h11l-2 4 2 4H5")),
    Clock(Part("M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z"), Part("M12 7v5l3 2")),
    Bolt(Part("M13 2L4 14h7l-1 8 9-12h-7z", fill = true)),
    Check(Part("M4.5 12.5l5 5L19.5 7")),
    Heart(Part("M12 20.5s-8-4.9-8-11A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5c0 6.1-8 11-8 11z")),
    HeartFill(Part("M12 20.5s-8-4.9-8-11A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5c0 6.1-8 11-8 11z", fill = true)),
}

/**
 * Draws [sym] in a square of [size] dp. [weight] is the stroke width on the 24 grid (2 = regular,
 * 3 = semibold). [cut] is the color used for the check inside `CheckCircleFill` (match the surface).
 */
@Composable
internal fun Symbol(
    sym: Sym,
    size: Float,
    tint: Color,
    weight: Float = 2f,
    modifier: Modifier = Modifier,
    cut: Color = Color.Black,
) {
    val paths = remember(sym) { sym.parts.map { PathParser().parsePathString(it.d).toPath() } }
    Canvas(modifier.size(size.dp)) {
        val s = this.size.minDimension / 24f
        scale(s, s, pivot = Offset.Zero) {
            sym.parts.forEachIndexed { i, part ->
                if (part.fill) {
                    drawPath(paths[i], tint)
                } else {
                    drawPath(
                        paths[i],
                        if (part.cut) cut else tint,
                        style = Stroke(width = weight, cap = StrokeCap.Round, join = StrokeJoin.Round),
                    )
                }
            }
        }
    }
}

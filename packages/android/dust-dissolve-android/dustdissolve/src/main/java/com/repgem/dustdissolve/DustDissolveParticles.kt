//
//  DustDissolveParticles.kt
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: Android 7.0 (API 24); AGSL shader on Android 13+ (API 33)
//
//  The dust: a cloud of round pastel dots born exactly where the shader eats the view away,
//  hanging for a moment, then flowing to a target, drifting away, or bursting outward.
//
package com.repgem.dustdissolve

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

// MARK: - Erosion field (shared with the AGSL shader)

/** The direction-adjusted coordinates the erosion field is built from. */
private fun directionXY(nx: Double, ny: Double, dir: DustDissolveDirection): DoubleArray = when (dir) {
    DustDissolveDirection.LeftToRight -> doubleArrayOf(nx, ny)
    DustDissolveDirection.RightToLeft -> doubleArrayOf(1 - nx, ny)
    DustDissolveDirection.TopToBottom -> doubleArrayOf(ny, nx)
    DustDissolveDirection.BottomToTop -> doubleArrayOf(1 - ny, nx)
    DustDissolveDirection.CenterOut -> {
        val dx = nx - 0.5
        val dy = ny - 0.5
        doubleArrayOf(min(sqrt(dx * dx + dy * dy) * 1.4, 1.0), nx + ny)
    }
}

/**
 * A smooth erosion field over the view (0…~1.05). A pixel disappears when the shader's threshold
 * passes its value, and a particle is born at the same moment.
 * Keep in sync with `dissolveField()` in the AGSL string (DustDissolveShader.kt).
 */
internal fun dissolveField(nx: Double, ny: Double, dir: DustDissolveDirection): Double {
    val xy = directionXY(nx, ny, dir)
    val x = xy[0]
    val y = xy[1]
    val a = sin(x * 17 + y * 6) * 0.5 + sin(x * 7 - y * 13 + 1.7) * 0.35 + sin(y * 21 + x * 3 + 0.6) * 0.25
    return x * 0.82 + (a * 0.5 + 0.5) * 0.22
}

/** Straight-edged version of the field, used by the fallback reveal (Android < 13). */
private fun linearField(nx: Double, ny: Double, dir: DustDissolveDirection): Double =
    directionXY(nx, ny, dir)[0] * 0.82 + 0.11

// MARK: - Particle model

internal class DustParticle(
    val nx: Double, val ny: Double,        // birth position inside the view (0…1)
    val spawnShader: Double,               // when the shader's erosion removes the pixel under this dot
    val spawnLinear: Double,               // same, for the straight-edged fallback (Android < 13)
    val dx: Double, val dy: Double,        // slow drift while the cloud hangs (mostly left / up), dp
    val flightDelay: Double,
    val dur: Double,
    val jx: Double, val jy: Double,        // lateral scatter
    val k: Double,                         // distance factor for drift / burst
    val aj: Double,                        // angle jitter for drift / burst
    val size: Double,                      // dp
    val colorIndex: Int,
    val twinkle: Double,
)

internal fun buildParticles(c: DustDissolveConfiguration): List<DustParticle> {
    val r = Random(c.seed)
    val paletteCount = max(c.palette.size, 1)
    fun spawn(f: Double): Double {
        val p = ((f + 0.06) / 1.2).coerceIn(0.0, 1.0)
        return c.dissolveStart + p * (c.dissolveEnd - c.dissolveStart)
    }
    return List(max(c.particleCount, 0)) {
        val nx: Double
        val ny: Double
        when (c.shape) {
            DustDissolveShape.Rectangle -> {
                nx = r.nextDouble(0.0, 1.0)
                ny = r.nextDouble(0.04, 0.96)
            }
            DustDissolveShape.Ellipse -> {
                val a = r.nextDouble(0.0, 2 * PI)
                val rad = sqrt(r.nextDouble(0.0, 1.0)) * 0.96
                nx = 0.5 + 0.5 * rad * cos(a)
                ny = 0.5 + 0.5 * rad * sin(a)
            }
        }
        val jitter = r.nextDouble(-0.05, 0.05)
        DustParticle(
            nx = nx, ny = ny,
            spawnShader = spawn(dissolveField(nx, ny, c.direction) + jitter),
            spawnLinear = spawn(linearField(nx, ny, c.direction) + jitter),
            dx = -r.nextDouble(12.0, 48.0),
            dy = r.nextDouble(-22.0, 10.0),
            flightDelay = r.nextDouble(0.0, max(c.flightStagger, 0.0001)),
            dur = r.nextDouble(c.flightDurationMin, max(c.flightDurationMax, c.flightDurationMin + 0.0001)),
            jx = r.nextDouble(-1.0, 1.0),
            jy = r.nextDouble(-1.0, 1.0),
            k = r.nextDouble(0.6, 1.4),
            aj = r.nextDouble(-1.0, 1.0),
            size = r.nextDouble(c.dotSizeMin.toDouble(), max(c.dotSizeMax, c.dotSizeMin + 0.0001f).toDouble()),
            colorIndex = r.nextInt(paletteCount),
            twinkle = r.nextDouble(0.0, 6.28),
        )
    }
}

// MARK: - Drawing

private fun bez(a: Double, b: Double, c: Double, d: Double, u: Double): Double {
    val m = 1 - u
    return m * m * m * a + 3 * m * m * u * b + 3 * m * u * u * c + u * u * u * d
}

/** Draws one frame of dust. `c` (source) and `g` (target) are in this DrawScope's own pixel space. */
internal fun DrawScope.drawDust(
    t: Double,
    c: Rect,
    g: Rect?,
    cfg: DustDissolveConfiguration,
    particles: List<DustParticle>,
    shaderErosion: Boolean,
) {
    val end = cfg.flightStart + cfg.flightStagger + cfg.flightDurationMax + 0.05
    if (t <= cfg.dissolveStart || t >= end || cfg.palette.isEmpty()) return

    var motion = cfg.motion
    var isFlow = false
    if (motion is DustDissolveMotion.FlowToTarget) {
        if (g == null) motion = DustDissolveMotion.Burst(120.dp) else isFlow = true
    }

    val d = density.toDouble()
    val w = size.width.toDouble()
    val h = size.height.toDouble()
    val p0x = c.center.x.toDouble(); val p0y = c.center.y.toDouble()
    val p3x = g?.center?.x?.toDouble() ?: p0x; val p3y = g?.center?.y?.toDouble() ?: p0y
    val p1x = w * 1.02; val p1y = p0y + h * 0.04
    val p2x = w * 0.82; val p2y = h * 0.80
    val shrink = if (isFlow) 1 - 0.3 * smooth(ramp(t, cfg.flightStart, cfg.flightStart + 1.05)) else 1.0

    for (i in particles.indices) {
        val p = particles[i]
        val spawn = if (shaderErosion) p.spawnShader else p.spawnLinear
        val age = t - spawn
        if (age < 0) continue

        val ownX = c.left + p.nx * c.width
        val ownY = c.top + p.ny * c.height
        val drift = easeOut(min(age / 0.55, 1.0))
        val baseX = ownX + p.dx * d * drift
        val baseY = ownY + p.dy * d * drift

        val fs = max(spawn + 0.05, cfg.flightStart + p.flightDelay)
        val u = ramp(t, fs, fs + p.dur)
        val e = smooth(u)

        var x = baseX
        var y = baseY
        var fadeStart = 0.9
        when (val m = motion) {
            is DustDissolveMotion.FlowToTarget -> {
                val k = sin(PI * e)
                x = bez(p0x, p1x, p2x, p3x, e) + (baseX - p0x) * (1 - e) + p.jx * 26 * d * k
                y = bez(p0y, p1y, p2y, p3y, e) + (baseY - p0y) * (1 - e) + p.jy * 26 * d * k
            }
            is DustDissolveMotion.Drift -> {
                val a = Math.toRadians(m.angleDegrees.toDouble()) + p.aj * 0.7
                val dist = m.distance.value * d * p.k
                val wob = (p.jy * 18 * sin(PI * e) + sin(e * 7 + p.twinkle) * 5 * e) * d
                x = baseX + cos(a) * dist * e - sin(a) * wob
                y = baseY + sin(a) * dist * e + cos(a) * wob
                fadeStart = 0.45
            }
            is DustDissolveMotion.Burst -> {
                val a = atan2(ownY - p0y, ownX - p0x) + p.aj * 0.5
                val dist = m.distance.value * d * p.k
                x = baseX + cos(a) * dist * e
                y = baseY + sin(a) * dist * e
                fadeStart = 0.40
            }
        }

        val tw = 0.8 + 0.2 * sin(t * 16 + p.twinkle)
        val alpha = ramp(age, 0.0, 0.06) * (1 - ramp(u, fadeStart, 1.0)) * tw
        if (alpha <= 0.01) continue

        val center = Offset(x.toFloat(), y.toFloat())
        val color = cfg.palette[p.colorIndex % cfg.palette.size]
        drawCircle(color.copy(alpha = alpha.toFloat().coerceIn(0f, 1f)), (p.size * shrink * d / 2).toFloat(), center)

        // A few of the dots flare into 4-point sparkles.
        if (cfg.sparkleEvery > 0 && i % cfg.sparkleEvery == 0) {
            val env = max(0.0, sin(t * 11 + p.twinkle))
            val r = ((3 + 7 * env * env) * d).toFloat()
            val star = Path().apply {
                val pts = floatArrayOf(0f, -1f, 0.16f, -0.16f, 1f, 0f, 0.16f, 0.16f, 0f, 1f, -0.16f, 0.16f, -1f, 0f, -0.16f, -0.16f)
                for (j in 0 until 8) {
                    val px = center.x + pts[j * 2] * r
                    val py = center.y + pts[j * 2 + 1] * r
                    if (j == 0) moveTo(px, py) else lineTo(px, py)
                }
                close()
            }
            drawPath(star, Color.White.copy(alpha = (alpha * (0.4 + 0.6 * env)).toFloat().coerceIn(0f, 1f)))
        }
    }
}

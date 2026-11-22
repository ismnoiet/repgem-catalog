//
//  DustDissolveShader.kt
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: Android 13 (API 33) for the shader; older versions use a straight-edged
//  reveal (see DustDissolve.kt).
//
//  One AGSL pass for the "source" view (any view):
//    1. a light shimmer line that crosses the view left -> right
//    2. a dissolve that eats the view away in any direction with a dithered, stippled edge
//       and a soft glowing rim
//
package com.repgem.dustdissolve

import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import androidx.annotation.RequiresApi
import androidx.compose.ui.graphics.asComposeRenderEffect

internal const val COUPON_AGSL = """
uniform shader content;      // the live view
uniform float2 size;         // view size in px
uniform float dpr;           // pixels per dp
uniform float progress;      // 0 = intact ... 1 = fully dissolved
uniform float shimmer;       // 0...1 position of the shimmer line (0 and 1 = off)
uniform float direction;     // 0 left->right, 1 right->left, 2 top->bottom, 3 bottom->top, 4 centre out

// Must match dissolveField() in DustDissolveParticles.kt, so the dust particles are born exactly
// where the view is eaten away.
float dissolveField(float2 uv) {
    int dir = int(direction + 0.5);
    float x = uv.x;
    float y = uv.y;
    if (dir == 1)      { x = 1.0 - uv.x; y = uv.y; }
    else if (dir == 2) { x = uv.y;       y = uv.x; }
    else if (dir == 3) { x = 1.0 - uv.y; y = uv.x; }
    else if (dir == 4) {
        float2 d = uv - 0.5;
        x = min(length(d) * 1.4, 1.0);
        y = uv.x + uv.y;
    }
    float a = sin(x * 17.0 + y * 6.0) * 0.5
            + sin(x * 7.0 - y * 13.0 + 1.7) * 0.35
            + sin(y * 21.0 + x * 3.0 + 0.6) * 0.25;
    return x * 0.82 + (a * 0.5 + 0.5) * 0.22;
}

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

half4 main(float2 coord) {
    half4 color = content.eval(coord);

    // 1. shimmer line (a slanted, soft band that only lights up the view's own pixels)
    if (shimmer > 0.0 && shimmer < 1.0) {
        float s = shimmer * shimmer * (3.0 - 2.0 * shimmer);
        float slant = 0.32;
        float d = coord.x + coord.y * slant;
        float span = size.x + size.y * slant + 80.0 * dpr;
        float c = -40.0 * dpr + span * s;
        float band = exp(-pow((d - c) / (14.0 * dpr), 2.0));
        color.rgb = min(color.rgb + half3(half(band * 0.55)) * color.a, half3(color.a));
    }

    if (progress <= 0.0) { return color; }

    // 2. dissolve
    float2 uv = coord / size;
    float f = dissolveField(uv);
    float th = -0.06 + 1.2 * progress;

    // Dithered edge: every pixel is either fully there or fully gone, so there is no soft alpha
    // and the edge never fades to black: it breaks into dots in the view's own colors.
    float n = hash21(floor(coord / (dpr * 0.67)));
    float d = f - th + 0.05;
    float vis = step(n * 0.10, d);

    float rim = vis * (1.0 - smoothstep(0.0, 0.05, d));
    half3 glow = half3(0.93, 0.88, 1.0) * color.a;
    half3 rgb = mix(color.rgb, glow, half(rim * 0.45));
    return half4(rgb, color.a) * half(vis);
}
"""

/** Owns the RuntimeShader for one source view. */
@RequiresApi(33)
internal class DustAgsl {
    private val shader = RuntimeShader(COUPON_AGSL)

    fun effect(width: Float, height: Float, density: Float, progress: Float, shimmer: Float, direction: Float): androidx.compose.ui.graphics.RenderEffect {
        shader.setFloatUniform("size", width, height)
        shader.setFloatUniform("dpr", density)
        shader.setFloatUniform("progress", progress)
        shader.setFloatUniform("shimmer", shimmer)
        shader.setFloatUniform("direction", direction)
        return RenderEffect.createRuntimeShaderEffect(shader, "content").asComposeRenderEffect()
    }
}

//
//  DustDissolve.metal
//  DustDissolve
//
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  One colorEffect pass for the "source" view:
//    1. an optional light shimmer line that crosses the view left -> right
//    2. a dissolve that eats the view away in any direction. The edge is dithered: every pixel is
//       either fully there or fully gone, so it breaks into dots in the view's own colors
//       (no soft fade to black).
//
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Must match dissolveField() in DustDissolveParticles.swift, so the dust particles are born exactly
// where the view is eaten away.
// dir: 0 left->right, 1 right->left, 2 top->bottom, 3 bottom->top, 4 centre out
static float dissolveField(float2 uv, int dir) {
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

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

/// - size:      the view's size in points
/// - progress:  0 = intact ... 1 = fully dissolved
/// - shimmer:   0...1 position of the shimmer line (0 and 1 = off)
/// - direction: see dissolveField()
[[ stitchable ]] half4 dustDissolve(float2 position, half4 color, float2 size, float progress, float shimmer, float direction) {
    // 1. shimmer line (a slanted, soft band that only lights up the view's own pixels)
    if (shimmer > 0.0 && shimmer < 1.0) {
        float s = shimmer * shimmer * (3.0 - 2.0 * shimmer);
        float slant = 0.32;
        float d = position.x + position.y * slant;
        float span = size.x + size.y * slant + 80.0;
        float c = -40.0 + span * s;
        float band = exp(-pow((d - c) / 14.0, 2.0));
        color.rgb = min(color.rgb + half3(half(band * 0.55)) * color.a, half3(color.a));
    }

    if (progress <= 0.0) { return color; }

    // 2. dissolve
    float2 uv = position / size;
    float f = dissolveField(uv, int(direction + 0.5));
    float th = -0.06 + 1.2 * progress;

    // Dithered edge: every pixel is either fully there or fully gone. There is no soft alpha,
    // so the edge never fades to black: it breaks into dots in the view's own colors.
    float n = hash21(floor(position / 1.6));
    float d = f - th + 0.05;
    float vis = step(n * 0.10, d);

    // the last pixels before they go catch a little light
    float rim = vis * (1.0 - smoothstep(0.0, 0.05, d));
    half3 glow = half3(0.93, 0.88, 1.0) * color.a;
    half3 rgb = mix(color.rgb, glow, half(rim * 0.45));
    return half4(rgb, color.a) * half(vis);
}

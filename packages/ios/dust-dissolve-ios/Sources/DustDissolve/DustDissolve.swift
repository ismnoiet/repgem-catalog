//
//  DustDissolve.swift
//  DustDissolve
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Three pieces:
//
//    DustDissolveScope(dust) { … }      a container that draws the dust on top of its content
//    .dustSource(dust)          the view that dissolves, the dust is born here
//    .dustTarget()              optional: where the dust flows to (the total, a cart badge…)
//
//  One scope can run many sources at once (a grid of tiles, the rows of a list): give each its own
//  controller and pass them all to the scope.
//
//  Positions travel as SwiftUI anchors, so the dust is always resolved in the scope's own
//  coordinate space. There is no manual frame math and no dependency on safe areas.
//
import SwiftUI

// MARK: - Anchors (source / target frames)

struct DustDissolveAnchors {
    var sources: [ObjectIdentifier: Anchor<CGRect>] = [:]
    /// `nil` key = the shared target every controller without its own target flows to.
    var targets: [ObjectIdentifier?: Anchor<CGRect>] = [:]
}

struct DustDissolveKey: PreferenceKey {
    static var defaultValue = DustDissolveAnchors()
    static func reduce(value: inout DustDissolveAnchors, nextValue: () -> DustDissolveAnchors) {
        let n = nextValue()
        value.sources.merge(n.sources) { $1 }
        value.targets.merge(n.targets) { $1 }
    }
}

// MARK: - Resources

private final class DustDissolveBundleToken {}

enum DustDissolveBundle {
    /// The bundle that holds the compiled Metal library (`DustDissolve.metal`).
    static var resources: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: DustDissolveBundleToken.self)   // CocoaPods
        #endif
    }
}

// MARK: - Scope

/// Wrap the screen (or the part of it the dust may fly across). It draws the dust over its
/// content and never takes touches.
///
///     DustDissolveScope(dust) {
///         VStack {
///             Ticket().dustSource(dust)
///             …
///             TotalRow().background { Color.clear.frame(width: 58, height: 19).dustTarget() }
///         }
///     }
///
/// Several views at once:
///
///     DustDissolveScope(tiles.map(\.dust)) { Grid { ForEach(tiles) { $0.view.dustSource($0.dust) } } }
public struct DustDissolveScope<Content: View>: View {
    private let controllers: [DustDissolveController]
    private let content: Content

    public init(_ controller: DustDissolveController, @ViewBuilder content: () -> Content) {
        self.controllers = [controller]
        self.content = content()
    }

    public init(_ controllers: [DustDissolveController], @ViewBuilder content: () -> Content) {
        self.controllers = controllers
        self.content = content()
    }

    public var body: some View {
        content.overlayPreferenceValue(DustDissolveKey.self) { anchors in
            GeometryReader { proxy in
                ZStack {
                    ForEach(controllers) { c in
                        if let s = anchors.sources[c.id] {
                            let target = (anchors.targets[c.id] ?? anchors.targets[nil]).map { proxy[$0] }
                            DustDissolveCanvas(controller: c, source: proxy[s], target: target)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct DustDissolveCanvas: View {
    @ObservedObject var controller: DustDissolveController
    let source: CGRect
    let target: CGRect?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Idle (or finished): no timeline, no frames, no canvas work.
        TimelineView(.animation(paused: !controller.isActive)) { tl in
            let t = controller.elapsed(at: tl.date)
            let cfg = controller.configuration
            let particles = controller.particles
            Canvas { ctx, size in
                guard !reduceMotion, let t else { return }
                drawDust(&ctx, size: size, t: t, source: source, target: target, particles: particles, config: cfg)
            }
        }
    }
}

// MARK: - Source

struct DustDissolveSourceModifier: ViewModifier {
    @ObservedObject var controller: DustDissolveController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !controller.isActive)) { tl in
            let cfg = controller.configuration
            let t = controller.elapsed(at: tl.date)
            let dissolve: Double = reduceMotion
                ? (t == nil ? 0 : 1)
                : (t.map { ramp($0, cfg.dissolveStart, cfg.dissolveEnd) } ?? 0)
            let shimmer: Double = (reduceMotion || !cfg.shimmer)
                ? 0
                : (t.map { ramp($0, cfg.shimmerStart, cfg.shimmerEnd) } ?? 0)
            let direction = Double(cfg.direction.rawValue)

            content.visualEffect { view, proxy in
                view.colorEffect(
                    ShaderLibrary.bundle(DustDissolveBundle.resources).dustDissolve(
                        .float2(proxy.size), .float(dissolve), .float(shimmer), .float(direction)
                    ),
                    isEnabled: dissolve > 0 || (shimmer > 0 && shimmer < 1)
                )
            }
        }
        .anchorPreference(key: DustDissolveKey.self, value: .bounds) { anchor in
            var a = DustDissolveAnchors()
            a.sources[ObjectIdentifier(controller)] = anchor
            return a
        }
    }
}

public extension View {
    /// Marks the view that dissolves (a coupon, a card, an avatar…). The dust is born where it is
    /// eaten away. Must sit inside a `DustDissolveScope` that was given the same controller.
    /// The view keeps its place in the layout, so nothing around it moves.
    func dustSource(_ controller: DustDissolveController) -> some View {
        modifier(DustDissolveSourceModifier(controller: controller))
    }

    /// Marks where the dust flows to (only used by `.flowToTarget`). The dots aim at the centre of
    /// this view's frame. Pass a controller to give that one its own target; with none, every
    /// controller in the scope that has no target of its own flows here.
    func dustTarget(for controller: DustDissolveController? = nil) -> some View {
        anchorPreference(key: DustDissolveKey.self, value: .bounds) { anchor in
            var a = DustDissolveAnchors()
            a.targets[controller.map { ObjectIdentifier($0) }] = anchor
            return a
        }
    }
}

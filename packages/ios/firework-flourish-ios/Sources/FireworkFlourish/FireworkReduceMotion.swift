//
//  FireworkReduceMotion.swift
//  FireworkFlourish
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// What a one-shot celebration does when Reduce Motion is on.
public enum FireworkReduceMotion {
    /// A brief still frame of bursts that fades in and out (about half a second). No rockets, drift or
    /// twinkle. The default, so the moment is still acknowledged.
    case fade
    /// Draw nothing.
    case none
}

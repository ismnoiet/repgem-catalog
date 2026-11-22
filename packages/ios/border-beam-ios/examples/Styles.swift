BorderBeam(.small, shape: .circle) { Image(systemName: "stop.fill").padding(12) }
BorderBeam(.line, shape: .capsule) { SearchField() }   // sweeps along the bottom edge
BorderBeam(direction: .rightToLeft, intensity: 0.75) { ... }
BorderBeam(colors: BeamPalette.single(.cyan)) { ... }  // one color

// Only the beam, on a view you style yourself
myView.borderBeam(shape: .rounded(12))

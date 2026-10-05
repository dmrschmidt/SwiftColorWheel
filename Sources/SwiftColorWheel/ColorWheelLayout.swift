import SwiftUI

/// How the wheel's colours are laid out.
public enum ColorWheelLayout: Hashable, Sendable {
    /// Paper swatches in rings: every hue at a handful of strengths. Discrete on purpose.
    case swatches(Swatches = Swatches())
    /// The original SwiftColorWheel: dots on rings, shrinking toward the centre.
    case dots(Dots = Dots())

    public struct Swatches: Hashable, Sendable {
        /// Swatches round each ring.
        public var hues: Int
        /// Rings, palest inside.
        public var rings: Int
        /// Where the innermost ring starts, as a fraction of the wheel's radius. The hole it
        /// leaves is where the centre view sits.
        public var innerRadius: Double
        /// Where the innermost ring starts when no centre view is shown and the rings can grow
        /// inward to fill the space.
        public var filledInnerRadius: Double
        /// The gap between neighbouring swatches, the same round the ring as between rings.
        public var gap: CGFloat
        /// A swatch's corner rounding.
        public var cornerRadius: CGFloat

        public init(hues: Int = 24, rings: Int = 5, innerRadius: Double = 0.36, filledInnerRadius: Double = 0.16, gap: CGFloat = 3, cornerRadius: CGFloat = 1) {
            self.hues = max(1, hues)
            self.rings = max(1, rings)
            self.innerRadius = min(0.9, max(0, innerRadius))
            self.filledInnerRadius = min(0.9, max(0, filledInnerRadius))
            self.gap = gap
            self.cornerRadius = cornerRadius
        }
    }

    /// The property names are the 1.x `ColorWheel`'s.
    public struct Dots: Hashable, Sendable {
        /// Radius of the white dot in the middle.
        public var centerRadius: CGFloat
        /// Smallest dot radius, toward the centre.
        public var minCircleRadius: CGFloat
        /// Largest dot radius, at the rim.
        public var maxCircleRadius: CGFloat
        /// Extra space between rings.
        public var innerPadding: CGFloat
        /// Degrees each ring is turned against the one outside it. Zero gives straight rays,
        /// anything else the spiral.
        public var shiftDegree: Double
        /// How tightly dots are packed round a ring.
        public var density: Double
        /// Space between the outermost dots and the wheel's edge.
        public var padding: CGFloat
        /// The hole the dots leave for the centre view when one is shown, as a fraction of the
        /// wheel's radius. The white centre dot goes with it.
        public var innerRadius: Double

        public init(centerRadius: CGFloat = 4, minCircleRadius: CGFloat = 1, maxCircleRadius: CGFloat = 6,
                    innerPadding: CGFloat = 2, shiftDegree: Double = 40, density: Double = 0.8, padding: CGFloat = 6, innerRadius: Double = 0.3) {
            self.centerRadius = centerRadius
            self.minCircleRadius = minCircleRadius
            self.maxCircleRadius = maxCircleRadius
            self.innerPadding = innerPadding
            self.shiftDegree = shiftDegree
            self.density = density
            self.padding = padding
            self.innerRadius = min(0.9, max(0, innerRadius))
        }
    }
}

/// One pickable colour on the wheel, in units that survive a resize.
struct WheelCell: Hashable, Sendable {
    /// Where it sits round the wheel before any turn, in radians. Also its hue.
    var angle: Double
    /// Its centre's distance from the hub, as a fraction of the wheel's radius.
    var distance: Double
    var saturation: Double
    var shape: Shape

    enum Shape: Hashable, Sendable {
        case dot(radius: CGFloat)
        /// `inner` and `outer` are fractions of the radius.
        case wedge(inner: Double, outer: Double, halfAngle: Double, inset: CGFloat, corner: CGFloat)
    }

    var hue: Double {
        let turns = angle / .fullTurn
        return turns - turns.rounded(.down)
    }
}

extension ColorWheelLayout {
    /// The hole in the middle, as a fraction of the radius.
    func hole(showsCenter: Bool) -> Double {
        switch self {
        case .swatches(let swatches): showsCenter ? swatches.innerRadius : swatches.filledInnerRadius
        case .dots(let dots): showsCenter ? dots.innerRadius : 0
        }
    }

    /// How far inside the wheel's edge the outermost cells are centred.
    var overhang: CGFloat {
        if case .dots(let dots) = self { dots.maxCircleRadius * 1.5 + dots.padding } else { 0 }
    }

    func cells(radius: CGFloat, showsCenter: Bool = false) -> [WheelCell] {
        switch self {
        case .swatches(let swatches): swatches.cells(innerRadius: hole(showsCenter: showsCenter))
        case .dots(let dots): dots.cells(radius: radius, hole: showsCenter ? radius * dots.innerRadius : 0)
        }
    }
}

private extension ColorWheelLayout.Swatches {
    func cells(innerRadius: Double) -> [WheelCell] {
        func edge(_ ring: Int) -> Double { innerRadius + (1 - innerRadius) * Double(ring) / Double(rings) }
        let halfAngle = Double.pi / Double(hues)
        return (0 ..< rings).flatMap { ring in
            (0 ..< hues).map { hue in
                WheelCell(angle: (Double(hue) + 0.5) * 2 * halfAngle,
                          distance: (edge(ring) + edge(ring + 1)) / 2,
                          saturation: Double(ring + 1) / Double(rings),
                          shape: .wedge(inner: edge(ring), outer: edge(ring + 1), halfAngle: halfAngle,
                                        inset: gap / 2 + cornerRadius, corner: cornerRadius))
            }
        }
    }
}

private extension ColorWheelLayout.Dots {
    // same loop as the 1.x layer. dots draw at 1.5x their radius like the old fill + stroke did
    func cells(radius: CGFloat, hole: CGFloat) -> [WheelCell] {
        guard radius > 0 else { return [] }
        func dotRadius(_ distance: Double) -> CGFloat { distance > 0 ? max(minCircleRadius, maxCircleRadius * distance) : centerRadius }
        let shift = shiftDegree * .pi / 180
        var cells: [WheelCell] = []
        var ring = radius, previous = dotRadius(1), current = previous
        repeat {
            let distance = Double(ring / radius)
            current = dotRadius(distance)
            let count = 2 * current > ring ? 1 : max(1, Int(density * .pi / asin(Double(2 * current / ring))))
            for index in 0 ..< count where ring - current * 1.5 >= hole + 3 {
                cells.append(WheelCell(angle: Double(index) * .fullTurn / Double(count) + shift * distance,
                                       distance: distance, saturation: distance, shape: .dot(radius: current * 1.5)))
            }
            ring -= max(1, previous + 2 * current + innerPadding)
            previous = current
        } while ring > 2 * centerRadius + current
        if hole == 0 { cells.append(WheelCell(angle: 0, distance: 0, saturation: 0, shape: .dot(radius: centerRadius * 1.5))) }
        return cells
    }
}

extension Double {
    static let fullTurn = 2 * Double.pi
}

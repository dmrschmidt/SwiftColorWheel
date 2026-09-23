import SwiftUI

/// Everything about a `ColorWheel` that can be changed. Each optional part is `nil` when off.
public struct ColorWheelConfiguration: Hashable, Sendable {
    public var layout: ColorWheelLayout
    /// The frame drawn round the picked colour.
    public var selectionRing: SelectionRing?
    /// The glass magnifier that sits beside the pick.
    public var loupe: Loupe?
    /// The glass the wheel is set in.
    public var dome: Dome?
    /// The tick ring that turns with the wheel under a fixed pointer.
    public var ticks: Ticks?
    /// Whether the wheel's centre view is shown. Without it the colours grow inward to fill
    /// the middle.
    public var showsCenter: Bool
    /// Whether the centre view sits on a glass disc.
    public var showsCenterDisc: Bool
    public var motion: Motion
    /// A selection tick each time the pick changes.
    public var haptics: Bool

    public init(layout: ColorWheelLayout = .swatches(), selectionRing: SelectionRing? = SelectionRing(), loupe: Loupe? = Loupe(),
                dome: Dome? = Dome(), ticks: Ticks? = nil, showsCenter: Bool = true, showsCenterDisc: Bool = true, motion: Motion = Motion(), haptics: Bool = true) {
        self.layout = layout
        self.selectionRing = selectionRing
        self.loupe = loupe
        self.dome = dome
        self.ticks = ticks
        self.showsCenter = showsCenter
        self.showsCenterDisc = showsCenterDisc
        self.motion = motion
        self.haptics = haptics
    }

    /// Swatches under a glass dome, the pick framed like a print.
    public static let underGlass = ColorWheelConfiguration()
    /// The same on a print plate: a tick ring under a pointer, the pick in highlighter.
    public static let plate = ColorWheelConfiguration(selectionRing: SelectionRing(color: .highlighter), ticks: Ticks())
    /// The 1.x wheel: the dot spiral, bare.
    public static let classic = ColorWheelConfiguration(layout: .dots(), loupe: nil, dome: nil, showsCenter: false)

    public struct SelectionRing: Hashable, Sendable {
        public var color: Color
        /// The hairline either side of the ring, which keeps it legible on any swatch.
        public var outline: Color
        public var width: CGFloat

        public init(color: Color = .white, outline: Color = .black, width: CGFloat = 3.5) {
            self.color = color
            self.outline = outline
            self.width = width
        }
    }

    public struct Loupe: Hashable, Sendable {
        public var diameter: CGFloat

        public init(diameter: CGFloat = 78) {
            self.diameter = diameter
        }
    }

    public struct Dome: Hashable, Sendable {
        public var glass: Glass
        /// How far the glass reaches past the wheel's edge.
        public var overhang: CGFloat

        public init(glass: Glass = .drawn, overhang: CGFloat = 11) {
            self.glass = glass
            self.overhang = overhang
        }

        public enum Glass: Hashable, Sendable {
            /// A dome painted by hand over the colours: a rim they glow into, and a sheen across
            /// the top. Looks the same on any background.
            case drawn
            /// A plate of the system's Liquid Glass under the colours, which glow onto it. It
            /// shows and bends whatever the wheel is placed over. Before iOS 26 it falls back
            /// to `drawn`.
            case liquid
        }
    }

    public struct Ticks: Hashable, Sendable {
        public var count: Int
        public var color: Color
        /// The fixed marker at the top that the ticks turn under.
        public var showsPointer: Bool

        public init(count: Int = 100, color: Color = .primary.opacity(0.45), showsPointer: Bool = true) {
            self.count = count
            self.color = color
            self.showsPointer = showsPointer
        }
    }

    /// How the wheel turns. The defaults are a scroll view's where it has an equivalent.
    public struct Motion: Hashable, Sendable {
        /// Whether dragging turns the wheel for brightness. Off, the wheel only picks.
        public var isEnabled: Bool
        /// How fast a free spin dies away, per second. 2 is `UIScrollView`'s normal rate.
        public var friction: Double
        /// The spring that pulls an overshoot back to the limit.
        public var stiffness: Double
        /// The furthest the wheel can be dragged past either end, in radians.
        public var maxOvershoot: Double

        public init(isEnabled: Bool = true, friction: Double = 2, stiffness: Double = 220, maxOvershoot: Double = 1) {
            self.isEnabled = isEnabled
            self.friction = friction
            self.stiffness = stiffness
            self.maxOvershoot = maxOvershoot
        }
    }
}

public extension Color {
    /// Highlighter yellow, in Display P3 so it stays as loud on a phone as on paper.
    static let highlighter = Color(.displayP3, red: 0.941, green: 0.969, blue: 0.153)
}

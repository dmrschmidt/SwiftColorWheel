import SwiftUI

/// A colour the way the wheel holds it: where round the wheel it sits, how far from the centre,
/// and how far the wheel is turned up.
///
/// The wheel binds to this rather than to `Color` because the trip through `Color` loses what
/// the wheel needs to keep — black has no hue, so a wheel turned all the way down would forget
/// which swatch was picked.
public struct HSBColor: Hashable, Sendable {
    /// Position round the wheel, `0 ..< 1`.
    public var hue: Double
    /// Distance from the centre, `0 ... 1`.
    public var saturation: Double
    /// How far the wheel is turned up, `0 ... 1`.
    public var brightness: Double

    public init(hue: Double, saturation: Double, brightness: Double) {
        self.hue = hue - hue.rounded(.down)
        self.saturation = min(1, max(0, saturation))
        self.brightness = min(1, max(0, brightness))
    }

    public init(_ resolved: Color.Resolved) {
        let r = Double(resolved.red), g = Double(resolved.green), b = Double(resolved.blue)
        let high = max(r, g, b), span = high - min(r, g, b)
        var hue = 0.0
        if span > 0 {
            if high == r { hue = (g - b) / span } else if high == g { hue = (b - r) / span + 2 } else { hue = (r - g) / span + 4 }
            hue /= 6
        }
        self.init(hue: hue, saturation: high > 0 ? span / high : 0, brightness: high)
    }

    public init(_ color: Color, in environment: EnvironmentValues = EnvironmentValues()) {
        self.init(color.resolve(in: environment))
    }

    public var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }

    /// sRGB components, each `0 ... 1`.
    public var rgb: (red: Double, green: Double, blue: Double) {
        func channel(_ n: Double) -> Double {
            let k = (n + hue * 6).truncatingRemainder(dividingBy: 6)
            return brightness - brightness * saturation * max(0, min(k, 4 - k, 1))
        }
        return (channel(5), channel(3), channel(1))
    }
}

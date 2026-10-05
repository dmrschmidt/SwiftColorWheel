import SwiftUI

struct WheelFace: View {
    var geometry: WheelGeometry
    var rotation: Double
    var brightness: Double
    var ticks: ColorWheelConfiguration.Ticks?

    var body: some View {
        Canvas { context, _ in
            for cell in geometry.cells {
                context.draw(cell, in: geometry, rotation: rotation, brightness: brightness)
            }
            if let ticks { draw(ticks, in: &context) }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ ticks: ColorWheelConfiguration.Ticks, in context: inout GraphicsContext) {
        let center = geometry.center, start = geometry.radius + WheelGeometry.tickStart
        var marks = Path()
        for index in 0 ..< max(0, ticks.count) {
            let angle = rotation + Double(index) * .fullTurn / Double(ticks.count)
            let end = geometry.radius + (index % 10 == 0 ? WheelGeometry.tickLongEnd : WheelGeometry.tickEnd)
            marks.move(to: CGPoint(x: center.x + start * cos(angle), y: center.y + start * sin(angle)))
            marks.addLine(to: CGPoint(x: center.x + end * cos(angle), y: center.y + end * sin(angle)))
        }
        context.stroke(marks, with: .color(ticks.color), lineWidth: 1)
        guard ticks.showsPointer else { return }
        var pointer = Path()
        pointer.move(to: CGPoint(x: center.x - 5, y: 0))
        pointer.addLine(to: CGPoint(x: center.x + 5, y: 0))
        pointer.addLine(to: CGPoint(x: center.x, y: 9))
        pointer.closeSubpath()
        context.fill(pointer, with: .color(.primary))
    }
}

/// The picked cell and its ring, drawn above the dome.
struct Pick: View {
    var geometry: WheelGeometry
    var rotation: Double
    var brightness: Double
    var selected: Int
    var ring: ColorWheelConfiguration.SelectionRing

    var body: some View {
        Canvas { context, _ in
            guard geometry.cells.indices.contains(selected) else { return }
            let cell = geometry.cells[selected]
            let frame = geometry.path(for: cell, rotation: rotation, grow: ring.width / 2 + 3.25)
            let style = { StrokeStyle(lineWidth: $0, lineJoin: .round) }
            context.stroke(frame, with: .color(ring.outline), style: style(ring.width + 2.5))
            context.stroke(frame, with: .color(ring.color), style: style(ring.width))
            context.draw(cell, in: geometry, rotation: rotation, brightness: brightness)
        }
        .allowsHitTesting(false)
    }
}

private extension GraphicsContext {
    func draw(_ cell: WheelCell, in geometry: WheelGeometry, rotation: Double, brightness: Double) {
        let path = geometry.path(for: cell, rotation: rotation)
        let color = GraphicsContext.Shading.color(Color(hue: cell.hue, saturation: cell.saturation, brightness: brightness))
        fill(path, with: color)
        if case .wedge(_, _, _, _, let corner) = cell.shape, corner > 0 {
            stroke(path, with: color, style: StrokeStyle(lineWidth: corner * 2, lineJoin: .round))
        }
    }
}

/// Under the colours: the shadow, and the Liquid Glass plate.
struct DomeBase: View {
    var dome: ColorWheelConfiguration.Dome
    var radius: CGFloat
    var rotation: Double
    var brightness: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.22))
                .blur(radius: 18)
                .offset(y: 16)
                .mask { Rectangle().padding(-80).overlay { Circle().blendMode(.destinationOut) }.compositingGroup() }
            if dome.isLiquid, #available(iOS 26, macOS 26, visionOS 26, *) {
                Circle().fill(.clear).glassEffect(.regular, in: Circle())
                RimGlow(dome: dome, radius: radius, rotation: rotation, brightness: brightness)
            }
        }
        .frame(width: (radius + dome.overhang) * 2, height: (radius + dome.overhang) * 2)
        .allowsHitTesting(false)
    }
}

/// Over the colours: the drawn dome.
struct DomeTop: View {
    var dome: ColorWheelConfiguration.Dome
    var radius: CGFloat
    var rotation: Double
    var brightness: Double

    var body: some View {
        if !dome.isLiquid {
            ZStack {
                RimGlow(dome: dome, radius: radius, rotation: rotation, brightness: brightness)
                Circle().strokeBorder(.white.opacity(0.35), lineWidth: dome.overhang)
                Circle().fill(.radialGradient(colors: [.white.opacity(0.5), .white.opacity(0)], center: UnitPoint(x: 0.3, y: 0.18),
                                              startRadius: 0, endRadius: radius * 0.76))
                Circle().fill(.radialGradient(colors: [.white.opacity(0.2), .white.opacity(0)], center: UnitPoint(x: 0.72, y: 0.9),
                                              startRadius: 0, endRadius: radius * 0.72))
                Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1)
            }
            .frame(width: (radius + dome.overhang) * 2, height: (radius + dome.overhang) * 2)
            .allowsHitTesting(false)
        }
    }
}

extension ColorWheelConfiguration.Dome {
    var isLiquid: Bool {
        if glass == .liquid, #available(iOS 26, macOS 26, visionOS 26, *) { true } else { false }
    }
}

/// The edge colours cast onto the rim of the glass.
private struct RimGlow: View {
    var dome: ColorWheelConfiguration.Dome
    var radius: CGFloat
    var rotation: Double
    var brightness: Double

    var body: some View {
        ZStack {
            ring.blur(radius: 2.5).mask { falloff([(0, 0.85), (0.3, 0.3), (1, 0)]) }
            ring.blur(radius: 7).mask { falloff([(0, 0.3), (1, 0.12)]) }
        }
    }

    private var ring: some View {
        let hues = stride(from: 1.0, through: 0, by: -1.0 / 24).map { Color(hue: $0, saturation: 1, brightness: brightness) }
        return Circle()
            .strokeBorder(AngularGradient(colors: hues, center: .center, angle: .radians(rotation)), lineWidth: dome.overhang + 4)
    }

    private func falloff(_ steps: [(across: CGFloat, opacity: Double)]) -> some View {
        let edge = radius / (radius + dome.overhang)
        let stops = [Gradient.Stop(color: .clear, location: edge - 0.001)]
            + steps.map { Gradient.Stop(color: .black.opacity($0.opacity), location: edge + (1 - edge) * $0.across) }
        return Circle().fill(.radialGradient(Gradient(stops: stops), center: .center, startRadius: 0, endRadius: radius + dome.overhang))
    }
}

struct Loupe: View {
    var color: Color
    var diameter: CGFloat
    var isHidden: Bool

    var body: some View {
        Circle()
            .fill(color)
            .padding(diameter * 0.18)
            .frame(width: diameter, height: diameter)
            .wheelGlass()
            .animation(isHidden ? .timingCurve(0.36, 0, 0.66, -0.56, duration: 0.28) : .timingCurve(0.34, 1.56, 0.64, 1, duration: 0.45)) {
                $0.scaleEffect(isHidden ? 0.2 : 1)
            }
            .animation(isHidden ? .easeIn(duration: 0.14).delay(0.14) : .easeOut(duration: 0.18)) {
                $0.opacity(isHidden ? 0 : 1)
            }
            .allowsHitTesting(false)
    }
}

extension View {
    @ViewBuilder
    func wheelGlass(isOn: Bool = true) -> some View {
        if !isOn {
            clipShape(Circle())
        } else if #available(iOS 26, macOS 26, visionOS 26, *) {
            clipShape(Circle()).glassEffect(.regular, in: Circle())
        } else {
            clipShape(Circle())
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1) }
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
    }
}

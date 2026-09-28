import SwiftUI

/// A colour wheel. Tap picks a colour; turning the wheel dims and brightens it.
///
///     @State private var color = HSBColor(hue: 0.35, saturation: 0.8, brightness: 0.94)
///
///     ColorWheel(selection: $color)
///     ColorWheel(selection: $color, configuration: .plate) { color in
///         Text(color.brightness, format: .percent.precision(.fractionLength(0)))
///     }
///
/// Setting `selection` from outside turns the wheel to that colour. The wheel is square and
/// takes the smaller of the sides it is offered.
public struct ColorWheel<Center: View>: View {
    @Binding private var selection: HSBColor
    private let configuration: ColorWheelConfiguration
    private let center: (HSBColor) -> Center

    @State private var model = WheelModel()

    /// - Parameter center: what sits in the middle of a layout that has a hole, given the
    ///   colour as it changes.
    public init(selection: Binding<HSBColor>, configuration: ColorWheelConfiguration = .underGlass,
                @ViewBuilder center: @escaping (HSBColor) -> Center) {
        self.init(selection: selection, configuration: configuration, hasCenter: true, center: center)
    }

    private init(selection: Binding<HSBColor>, configuration: ColorWheelConfiguration, hasCenter: Bool, center: @escaping (HSBColor) -> Center) {
        _selection = selection
        var configuration = configuration
        configuration.showsCenter = configuration.showsCenter && hasCenter
        self.configuration = configuration
        self.center = center
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            layers
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .onChange(of: side, initial: true) { model.layout(side: side, configuration: configuration, showing: selection) }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: configuration) { model.layout(side: model.geometry.side, configuration: configuration, showing: selection) }
        // don't write back in the same frame an outside colour arrives, onChange would fire twice
        .onChange(of: selection) { _, color in
            guard !model.emitted.contains(color) else { return }
            model.spin(to: color)
            model.holdsNextEmission = true
        }
        .background { FrameClock(isRunning: model.isAnimating) { now in drive { model.tick(now) } } }
        .sensoryFeedback(trigger: model.selected) { _, _ in configuration.haptics ? .selection : nil }
        .accessibilityElement()
        .accessibilityLabel(Text("Colour wheel"))
        .accessibilityValue(Text("Hue \(Int(model.color.hue * 360)) degrees, saturation \(Int(model.color.saturation * 100)) percent, brightness \(Int(model.color.brightness * 100)) percent"))
        .accessibilityAdjustableAction { direction in
            model.nudgeBrightness(by: direction == .increment ? 0.1 : -0.1)
        }
    }

    private func drive(_ change: () -> Void) {
        change()
        let color = model.color
        guard !model.holdsNextEmission else { return model.holdsNextEmission = false }
        guard color != selection else { return }
        model.didEmit(color)
        selection = color
    }

    private var layers: some View {
        let geometry = model.geometry, rotation = model.motion.rotation, brightness = model.motion.brightness
        return ZStack {
            if let dome = configuration.dome {
                DomeBase(dome: dome, radius: geometry.radius, rotation: rotation, brightness: brightness)
            }
            WheelFace(geometry: geometry, rotation: rotation, brightness: brightness, ticks: configuration.ticks)
            centerView(in: geometry)
            if let dome = configuration.dome {
                DomeTop(dome: dome, radius: geometry.radius, rotation: rotation, brightness: brightness)
            }
            if let ring = configuration.selectionRing {
                Pick(geometry: geometry, rotation: rotation, brightness: brightness, selected: model.selected, ring: ring)
            }
            if let loupe = configuration.loupe {
                Loupe(color: model.color.color, diameter: loupe.diameter, isHidden: model.isLoupeHidden)
                    .position(model.loupeCenter)
                    // glide on tap only
                    .animation(.easeOut(duration: 0.18), value: model.selected)
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in drive { model.touch(at: value.location) } }
            .onEnded { value in drive { model.lift(at: value.location) } })
    }
}

private extension ColorWheel {
    @ViewBuilder func centerView(in geometry: WheelGeometry) -> some View {
        if configuration.showsCenter, geometry.hole > 0 {
            center(model.color)
                .frame(width: geometry.hole * 2, height: geometry.hole * 2)
                .wheelGlass(isOn: configuration.showsCenterDisc)
                .allowsHitTesting(false)
        }
    }
}

public extension ColorWheel where Center == EmptyView {
    init(selection: Binding<HSBColor>, configuration: ColorWheelConfiguration = .underGlass) {
        self.init(selection: selection, configuration: configuration, hasCenter: false) { _ in EmptyView() }
    }
}

private struct FrameClock: View {
    var isRunning: Bool
    var tick: (Date) -> Void

    var body: some View {
        TimelineView(.animation(paused: !isRunning)) { timeline in
            Color.clear.onChange(of: timeline.date) { _, now in tick(now) }
        }
    }
}

#Preview("Under glass") {
    @Previewable @State var color = HSBColor(hue: 0.35, saturation: 0.8, brightness: 0.94)
    ColorWheel(selection: $color).padding()
}

#Preview("Plate") {
    @Previewable @State var color = HSBColor(hue: 0.35, saturation: 0.8, brightness: 0.94)
    ColorWheel(selection: $color, configuration: .plate).padding()
}

#Preview("Classic") {
    @Previewable @State var color = HSBColor(hue: 0.6, saturation: 0.7, brightness: 1)
    ColorWheel(selection: $color, configuration: .classic).padding()
}

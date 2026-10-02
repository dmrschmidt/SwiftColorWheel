import SwiftColorWheel
import SwiftUI

/// A colour in `@State`, a `ColorWheel` bound to it. The suggestions row and the tray are plain
/// views of this app, not part of the library.
struct PickerScreen: View {
    /// `-preset plate` on the command line opens on that preset.
    @AppStorage("preset") private var preset = Preset.underGlass
    @State private var color = HSBColor(hue: 8.5 / 24, saturation: 0.8, brightness: 0.94)
    @State private var configuration = ColorWheelConfiguration.underGlass

    var body: some View {
        VStack(spacing: 0) {
            header
            ColorWheel(selection: $color, configuration: configuration) { color in
                BrightnessLabel(brightness: color.brightness)
            }
            .overlay { if configuration.ticks != nil { CropMarks().stroke(.primary.opacity(0.5), lineWidth: 1) } }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            Text("Tap a colour · turn the wheel to dim")
                .stamp()
                .padding(.top, 10)
            SuggestedColors(selection: $color)
                .padding(.top, 22)
            Spacer(minLength: 16)
            SelectionTray(color: color)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .background { Paper(isRuled: configuration.ticks != nil) }
        .onChange(of: preset, initial: true) { configuration = preset.configuration }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack {
            Picker("Preset", selection: $preset) {
                ForEach(Preset.allCases, id: \.self) { Text($0.title) }
            }
            .pickerStyle(.segmented)
            Menu {
                options
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder private var options: some View {
        Picker("Layout", selection: $configuration.layout) {
            Text("Swatches").tag(ColorWheelLayout.swatches())
            Text("Dots").tag(ColorWheelLayout.dots())
            Text("Dots, straight").tag(ColorWheelLayout.dots(.init(shiftDegree: 0, density: 1)))
        }
        Picker("Selection ring", selection: $configuration.selectionRing) {
            Text("None").tag(ColorWheelConfiguration.SelectionRing?.none)
            Text("Print").tag(ColorWheelConfiguration.SelectionRing?.some(.init()))
            Text("Highlighter").tag(ColorWheelConfiguration.SelectionRing?.some(.init(color: .highlighter)))
        }
        Toggle("Loupe", isOn: isOn(\.loupe, default: .init()))
        Picker("Dome", selection: $configuration.dome) {
            Text("None").tag(ColorWheelConfiguration.Dome?.none)
            Text("Liquid Glass").tag(ColorWheelConfiguration.Dome?.some(.init(glass: .liquid)))
            Text("Drawn").tag(ColorWheelConfiguration.Dome?.some(.init(glass: .drawn)))
        }
        Toggle("Tick ring", isOn: isOn(\.ticks, default: .init()))
        Toggle("Centre label", isOn: $configuration.showsCenter)
        Toggle("Centre disc", isOn: $configuration.showsCenterDisc)
        Toggle("Turn for brightness", isOn: $configuration.motion.isEnabled)
        Toggle("Haptics", isOn: $configuration.haptics)
    }

    /// A switch for a part of the configuration that is off when `nil`.
    private func isOn<Part>(_ part: WritableKeyPath<ColorWheelConfiguration, Part?>, default value: Part) -> Binding<Bool> {
        Binding { configuration[keyPath: part] != nil } set: { configuration[keyPath: part] = $0 ? value : nil }
    }
}

enum Preset: String, CaseIterable {
    case underGlass, plate, classic

    var title: String {
        switch self {
        case .underGlass: "Under glass"
        case .plate: "Plate"
        case .classic: "Classic"
        }
    }

    var configuration: ColorWheelConfiguration {
        switch self {
        case .underGlass: .underGlass
        case .plate: .plate
        case .classic: .classic
        }
    }
}

/// What the example puts in the middle of the wheel: the brightness, as a plate number.
struct BrightnessLabel: View {
    var brightness: Double

    private var percent: Int { Int((brightness * 100).rounded()) }

    var body: some View {
        VStack(spacing: 0) {
            Text("Bright").stamp()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("No.").font(.system(size: 13, weight: .bold, design: .serif)).italic()
                Text(percent, format: .number.precision(.integerLength(2)))
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .italic()
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(percent)))
                    .animation(.default, value: percent)
            }
        }
    }
}

extension View {
    /// The tracked typewriter eyebrow.
    func stamp() -> some View {
        font(.system(size: 10.5, weight: .bold, design: .monospaced))
            .tracking(1.7)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

/// Warm paper, ruled like graph paper when the wheel is on its plate.
private struct Paper: View {
    var isRuled: Bool

    var body: some View {
        LinearGradient(colors: [Color(red: 0.969, green: 0.949, blue: 0.918), Color(red: 0.929, green: 0.898, blue: 0.847)],
                       startPoint: .top, endPoint: .bottom)
            .overlay {
                if isRuled {
                    Canvas { context, size in
                        var rules = Path()
                        for x in stride(from: 0, through: size.width, by: 20) { rules.addRect(CGRect(x: x, y: 0, width: 1, height: size.height)) }
                        for y in stride(from: 0, through: size.height, by: 20) { rules.addRect(CGRect(x: 0, y: y, width: size.width, height: 1)) }
                        context.fill(rules, with: .color(.black.opacity(0.035)))
                    }
                }
            }
            .ignoresSafeArea()
    }
}

/// A printer's crop marks at the four corners.
private struct CropMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (x, dx) in [(rect.minX, 14.0), (rect.maxX, -14.0)] {
            for (y, dy) in [(rect.minY, 14.0), (rect.maxY, -14.0)] {
                path.move(to: CGPoint(x: x + dx, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + dy))
            }
        }
        return path
    }
}

#Preview {
    PickerScreen()
}

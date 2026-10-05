import SwiftColorWheel
import SwiftUI

/// A row of colours to jump to. Writing to the wheel's binding is all it takes: the wheel
/// moves its pick there and turns itself to the brightness.
struct SuggestedColors: View {
    @Binding var selection: HSBColor
    var colors = HSBColor.suggested

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested").stamp()
            HStack(spacing: 10) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Button {
                        selection = color
                    } label: {
                        Print(color: color.color, size: CGSize(width: 28, height: 31), border: 3)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -3 : 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.name)
                }
            }
        }
    }
}

/// A colour as a small photo print: white border, deeper at the foot.
struct Print: View {
    var color: Color
    var size: CGSize
    var border: CGFloat

    var body: some View {
        color
            .frame(width: size.width, height: size.height)
            .padding(EdgeInsets(top: border, leading: border, bottom: border * 2.5, trailing: border))
            .background(.white, in: RoundedRectangle(cornerRadius: 2))
            .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1.5)
    }
}

extension HSBColor {
    /// Blush to navy. Each sits on a swatch of the default wheel — hue step of 24, strength
    /// ring of 5 — at a brightness of its own.
    static let suggested: [HSBColor] = [(21, 0, 1), (22, 3, 0.96), (23, 4, 0.48), (2, 3, 0.86), (4, 2, 0.5), (6, 1, 0.72), (11, 3, 0.45), (15, 4, 0.3)]
        .map { hue, ring, brightness in HSBColor(hue: (Double(hue) + 0.5) / 24, saturation: Double(ring + 1) / 5, brightness: brightness) }
}

import SwiftColorWheel
import SwiftUI

/// What is picked, as a tilted print with its name and numbers, on a glass tray.
struct SelectionTray: View {
    var color: HSBColor

    var body: some View {
        HStack(spacing: 18) {
            Print(color: color.color, size: CGSize(width: 64, height: 70), border: 6)
                .overlay(alignment: .bottom) {
                    Text(color.hex)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.bottom, 3)
                }
                .rotationEffect(.degrees(-4))
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected").stamp()
                Text(color.name)
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .italic()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("H \(Int(color.hue * 360))° · S \(Int((color.saturation * 100).rounded())) · B \(Int((color.brightness * 100).rounded()))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

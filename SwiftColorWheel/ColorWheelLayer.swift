import UIKit

class ColorWheelLayer: CALayer {
    @NSManaged var brightness: CGFloat

    // swiftlint:disable force_cast
    private var padding: CGFloat { return (delegate as! ColorWheel).padding }
    private var centerRadius: CGFloat { return (delegate as! ColorWheel).centerRadius }
    private var minCircleRadius: CGFloat { return (delegate as! ColorWheel).minCircleRadius }
    private var maxCircleRadius: CGFloat { return (delegate as! ColorWheel).maxCircleRadius }
    private var innerPadding: CGFloat { return (delegate as! ColorWheel).innerPadding }
    private var shiftDegree: CGFloat { return (delegate as! ColorWheel).shiftDegree }
    private var density: CGFloat { return (delegate as! ColorWheel).density }
    // swiftlint:enable force_cast

    private let defaultBrightness: CGFloat = 1.0

    override init(layer: Any) {
        super.init(layer: layer)
        brightness = (layer as? ColorWheelLayer)?.brightness ?? 1.0
    }

    override init() {
        super.init()
        brightness = defaultBrightness
    }

    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)!
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(brightness) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in context: CGContext) {
        super.draw(in: context)
        UIGraphicsPushContext(context)

        let outerRadius = radius(in: bounds)
        var innerRadius = outerRadius
        var prevDotRadius = dotRadius(distance: 1)
        var currentDotRadius: CGFloat
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)

        repeat {
            let distance = innerRadius / outerRadius
            currentDotRadius = dotRadius(distance: distance)

            arcPositions(dotRadius: currentDotRadius, on: innerRadius).forEach { rad in
                drawCircle(around: center, on: outerRadius, of: context, rad: rad, distance: distance)
            }
            innerRadius -= (prevDotRadius + 2 * currentDotRadius + innerPadding)
            prevDotRadius = currentDotRadius
        } while innerRadius > 2 * centerRadius + currentDotRadius

        drawCircle(around: center, on: outerRadius, of: context, rad: 0, distance: 0)
        UIGraphicsPopContext()
    }

    func radius(in rect: CGRect) -> CGFloat {
        return min(rect.size.width, rect.size.height) / 2 - padding
    }

    func color(at rad: CGFloat, distance: CGFloat) -> UIColor {
        return UIColor(hue: rad / (2 * .pi), saturation: distance, brightness: brightness, alpha: 1)
    }
}

fileprivate extension ColorWheelLayer {
    func arcPositions(dotRadius: CGFloat, on radius: CGFloat) -> [CGFloat] {
        let circlesFitting = (2 * dotRadius) > radius
                ? 1
                : max(1, Int((density * .pi / (asin((2 * dotRadius) / radius)))))
        let stepSize = 2 * .pi / CGFloat(circlesFitting - 1)
        return (0..<circlesFitting).map { CGFloat($0) * stepSize }
    }

    func drawCircle(around center: CGPoint, on outerRadius: CGFloat, of context: CGContext, rad: CGFloat, distance: CGFloat) {
        let circleRadius = dotRadius(distance: distance)
        let center = position(around: center, on: outerRadius, rad: rad, distance: distance)
        let circleColor = color(at: rad, distance: distance)
        let circleRect = CGRect(x: center.x - circleRadius,
                y: center.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2)
        context.setLineWidth(circleRadius)
        context.setStrokeColor(circleColor.cgColor)
        context.setFillColor(circleColor.cgColor)
        context.addEllipse(in: circleRect)
        context.drawPath(using: .fillStroke)
    }

    func dotRadius(distance: CGFloat) -> CGFloat {
        guard distance > 0 else { return centerRadius }
        return max(minCircleRadius, maxCircleRadius * distance)
    }

    func position(around center: CGPoint, on radius: CGFloat, rad: CGFloat, distance: CGFloat) -> CGPoint {
        let shiftedRad = rad + (shiftDegree * distance) / 180 * .pi
        let x = center.x + (radius - padding) * distance * cos(-shiftedRad)
        let y = center.y + (radius - padding) * distance * sin(-shiftedRad)
        return CGPoint(x: x, y: y)
    }
}

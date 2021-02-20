import UIKit

class ColorWheelLayer: CALayer {
    @NSManaged var brightness: CGFloat

    var lastTouchPoint: CGPoint? {
        didSet {
            setNeedsDisplay()
        }
    }

    // swiftlint:disable force_cast
    private var padding: CGFloat { return (delegate as! ColorWheel).padding }
    private var centerRadius: CGFloat { return (delegate as! ColorWheel).centerRadius }
    private var minCircleRadius: CGFloat { return (delegate as! ColorWheel).minCircleRadius }
    private var maxCircleRadius: CGFloat { return (delegate as! ColorWheel).maxCircleRadius }
    private var innerPadding: CGFloat { return (delegate as! ColorWheel).innerPadding }
    private var shiftDegree: CGFloat { return (delegate as! ColorWheel).shiftDegree }
    private var density: CGFloat { return (delegate as! ColorWheel).density }
    private var highlightStrokeColor: UIColor? { return (delegate as! ColorWheel).highlightStrokeColor }
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
                drawPickerCircle(in: context, around: center, on: outerRadius, rad: rad, distance: distance)
            }
            innerRadius -= (prevDotRadius + 2 * currentDotRadius + innerPadding)
            prevDotRadius = currentDotRadius
        } while innerRadius > 2 * centerRadius + currentDotRadius

        drawPickerCircle(in: context, around: center, on: outerRadius, rad: 0, distance: 0)
        drawHighlightCircle(in: context, around: center, on: outerRadius)

        UIGraphicsPopContext()
    }

    func radius(in rect: CGRect) -> CGFloat {
        return min(rect.size.width, rect.size.height) / 2 - padding
    }

    func color(at rad: CGFloat, shiftedBy shiftDegree: CGFloat, distance: CGFloat) -> UIColor {
        let shiftedRad = rad + (shiftDegree * distance) / 180 * .pi
        return UIColor(hue: shiftedRad / (2 * .pi), saturation: distance, brightness: brightness, alpha: 1)
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

    func drawPickerCircle(in context: CGContext, around center: CGPoint, on outerRadius: CGFloat, rad: CGFloat, distance: CGFloat) {
        let circleRadius = dotRadius(distance: distance)
        let center = position(around: center, shiftedBy: shiftDegree, on: outerRadius, rad: rad, distance: distance)
        let circleColor = color(at: rad, shiftedBy: shiftDegree, distance: distance)
        let rect = circleRect(center: center, radius: circleRadius, modifier: 2)

        drawCircle(in: context, inside: rect, lineWidth: circleRadius, color: circleColor, strokeColor: circleColor)
    }

    func drawHighlightCircle(in context: CGContext, around center: CGPoint, on outerRadius: CGFloat) {
        guard let touchPoint = lastTouchPoint, let strokeColor = highlightStrokeColor else {
            return
        }

        let distance = sqrt(pow(touchPoint.x - center.x, 2) + pow(touchPoint.y - center.y, 2))
        let normDistance = distance / (radius(in: bounds) - padding)
        let rad = -(atan2(center.y - touchPoint.y, center.x - touchPoint.x) - CGFloat.pi)
        let circleColor = color(at: rad, shiftedBy: 0, distance: normDistance)
        let circleRadius = dotRadius(distance: normDistance)
        let lineWidth = circleRadius * 0.7
        let newCenter = position(around: center, shiftedBy: 0, on: outerRadius, rad: rad, distance: normDistance)
        let rect = circleRect(center: newCenter, radius: circleRadius, modifier: 3.6)

        drawCircle(in: context, inside: rect, lineWidth: lineWidth, color: circleColor, strokeColor: strokeColor)
    }

    func drawCircle(in context: CGContext, inside circleRect: CGRect, lineWidth: CGFloat, color: UIColor, strokeColor: UIColor) {
        context.setLineWidth(lineWidth)
        context.setStrokeColor(strokeColor.cgColor)
        context.setFillColor(color.cgColor)
        context.addEllipse(in: circleRect)
        context.drawPath(using: .fillStroke)
    }

    func circleRect(center: CGPoint, radius: CGFloat, modifier: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * modifier, height: radius * modifier)
    }

    func dotRadius(distance: CGFloat) -> CGFloat {
        guard distance > 0 else { return centerRadius }
        return max(minCircleRadius, maxCircleRadius * distance)
    }

    func position(around center: CGPoint, shiftedBy shiftDegree: CGFloat, on radius: CGFloat, rad: CGFloat, distance: CGFloat) -> CGPoint {
        let shiftedRad = rad + (shiftDegree * distance) / 180 * .pi
        let x = center.x + (radius - padding) * distance * cos(-shiftedRad)
        let y = center.y + (radius - padding) * distance * sin(-shiftedRad)
        return CGPoint(x: x, y: y)
    }
}

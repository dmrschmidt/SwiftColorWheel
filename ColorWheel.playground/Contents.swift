import UIKit
import PlaygroundSupport

class MyViewController : UIViewController, ColorWheelDelegate {
    private var colorWheel: RotatingColorWheel!
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        let colorWheelPos = CGRect(x: 50, y: 50, width: 300, height: 300)
        colorWheel = RotatingColorWheel(frame: colorWheelPos)
        colorWheel.delegate = self
        colorWheel.backgroundColor = .darkGray
        view.addSubview(colorWheel)
        
        let slider = UISlider(frame: CGRect(x: 50, y: 360, width: 300, height: 30))
        slider.value = 1.0
        slider.addTarget(self, action: #selector(sliderChanged(sender:)), for: .valueChanged)
        view.addSubview(slider)
        self.view = view
    }
    
    func didSelect(color: UIColor) {
        view.backgroundColor = color
    }
    
    @objc func sliderChanged(sender: UISlider) {
        colorWheel.frame = CGRect(x: 50.0, y: 50.0,
                                  width: Double(300 * sender.value),
                                  height: Double(300 * sender.value))
        colorWheel.brightness = CGFloat(sender.value)
    }
}

public protocol ColorWheelDelegate: class {
    func didSelect(color: UIColor)
}

public class RotatingColorWheel: ColorWheel {
    private var rotateRecognizer: UIRotationGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!
    private var originalRotation: CGFloat = 0
    private var lastAngle: CGFloat = 0
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareRotationRecognizers()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareRotationRecognizers()
    }
    
    @objc func didRotate(recognizer: UIRotationGestureRecognizer) {
        let newRotation = max(0, min(2 * .pi, originalRotation + recognizer.rotation))
        if recognizer.state == .changed {
            rotate(to: newRotation)
        } else if recognizer.state == .ended {
            originalRotation = newRotation
        }
    }
    
    func angleDelta(_ newAngle: CGFloat, _ oldAngle: CGFloat) -> CGFloat {
        return abs((abs(newAngle) - abs(oldAngle))) * movementDirection(newAngle, oldAngle)
    }
    
    func movementDirection(_ newAngle: CGFloat, _ oldAngle: CGFloat) -> CGFloat {
        let clockwise: CGFloat = 1
        let counterClockwise: CGFloat = -1
        if newAngle < 0 && oldAngle > 0 && abs(newAngle) > .pi / 2 {
            return clockwise
        } else if newAngle > 0 && oldAngle < 0 && abs(newAngle) > .pi / 2 {
            return counterClockwise
        } else if newAngle > oldAngle {
            return clockwise
        } else {
            return counterClockwise
        }
    }
    
    @objc func didPan(recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: superview!)
        let distance = normalizedDistance(to: touchPoint)
        guard distance <= 1.0 else { return }
        
        let center = convert(wheelCenter, to: superview!)
        let angle = angleTo(center: center, pointOnCircle: touchPoint)
        
        let newRotation = originalRotation + angleDelta(angle, lastAngle)
        if recognizer.state == .began {
            lastAngle = angle
        } else if recognizer.state == .changed {
            rotate(to: newRotation)
            lastAngle = angle
            originalRotation = newRotation
        } else if recognizer.state == .ended {
            originalRotation = newRotation
        }
    }
    
    func rotate(to radians: CGFloat) {
        transform = CGAffineTransform(rotationAngle: radians)
        //        brightness = newRotation / (2 * .pi)
    }
    
    private func prepareRotationRecognizers() {
        rotateRecognizer = UIRotationGestureRecognizer(target: self,
                                                       action: #selector(didRotate(recognizer:)))
        panRecognizer = UIPanGestureRecognizer(target: self,
                                               action: #selector(didPan(recognizer:)))
        addGestureRecognizer(rotateRecognizer)
        addGestureRecognizer(panRecognizer)
    }
}

public class ColorWheel: UIView {
    public weak var delegate: ColorWheelDelegate?
    public var padding: CGFloat = 12.0 {
        didSet { setNeedsDisplay() }
    }
    public var brightness: CGFloat = 1.0 {
        didSet { setNeedsDisplay() }
    }
    public var centerRadius: CGFloat = 4.0 {
        didSet { setNeedsDisplay() }
    }
    public var minCircleRadius: CGFloat = 1.0 {
        didSet { setNeedsDisplay() }
    }
    public var maxCircleRadius: CGFloat = 6.0 {
        didSet { setNeedsDisplay() }
    }
    public var innerPadding: CGFloat = 2 {
        didSet { setNeedsDisplay() }
    }
    public var shiftDegree: CGFloat = 40 {
        didSet { setNeedsDisplay() }
    }
    public var density: CGFloat = 0.8 {
        didSet { setNeedsDisplay() }
    }
    
    private var tapRecognizer: UITapGestureRecognizer!
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareTapRecognizer()
        contentMode = .redraw
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareTapRecognizer()
        contentMode = .redraw
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        let outerRadius = radius(in: rect)
        var innerRadius = outerRadius
        var prevDotRadius = dotRadius(distance: 1)
        var currentDotRadius: CGFloat
        let center = CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
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
        context.restoreGState()
    }
    
    private func arcPositions(dotRadius: CGFloat, on radius: CGFloat) -> [CGFloat] {
        let circlesFitting = (2 * dotRadius) > radius
            ? 1
            : max(1, Int((density * .pi / (asin((2 * dotRadius) / radius)))))
        let stepSize = 2 * .pi / CGFloat(circlesFitting - 1)
        return (0..<circlesFitting).map { CGFloat($0) * stepSize }
    }
    
    func drawCircle(around center: CGPoint, on outerRadius: CGFloat, of context: CGContext, rad: CGFloat, distance: CGFloat) {
        let circleRadius = dotRadius(distance: distance)
        let center = position(around: center, on: outerRadius, rad: rad, distance: distance)
        let circleColor = color(rad: rad, distance: distance)
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
    
    func normalizedDistance(to touchPoint: CGPoint) -> CGFloat {
        let distance = sqrt(pow(touchPoint.x - wheelCenter.x, 2) +
            pow(touchPoint.y - wheelCenter.y, 2))
        return distance / radius(in: bounds)
    }
    
    @objc func didRegisterTap(recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)
        let distance = normalizedDistance(to: touchPoint)
        guard distance <= 1.0 else { return }
        
        let angle = adjustedAngleTo(center: wheelCenter, pointOnCircle: touchPoint, distance: distance)
        let tappedColor = color(rad: angle, distance: distance)
        delegate?.didSelect(color: tappedColor)
    }
    
    func angleTo(center: CGPoint, pointOnCircle: CGPoint) -> CGFloat {
        let originX = pointOnCircle.x - center.x
        let originY = pointOnCircle.y - center.y
        return atan2(originY, originX)
    }
    
    func adjustedAngleTo(center: CGPoint, pointOnCircle: CGPoint, distance: CGFloat) -> CGFloat {
        var radians = angleTo(center: center, pointOnCircle: pointOnCircle)
        while radians < 0 { radians += CGFloat(2 * Double.pi) }
        let counterClockwise = 2 * .pi - (radians + (shiftDegree * distance) / 180 * .pi)
        return counterClockwise
    }
}

fileprivate extension ColorWheel {
    func radius(in rect: CGRect) -> CGFloat {
        return min(rect.size.width, rect.size.height) / 2 - padding
    }
    
    var wheelCenter: CGPoint {
        return CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
    }
    
    func prepareTapRecognizer() {
        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapRecognizer)
        tapRecognizer.addTarget(self, action: #selector(didRegisterTap(recognizer:)))
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
    
    func color(rad: CGFloat, distance: CGFloat) -> UIColor {
        return UIColor(hue: rad / (2 * .pi), saturation: distance, brightness: brightness, alpha: 1)
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()


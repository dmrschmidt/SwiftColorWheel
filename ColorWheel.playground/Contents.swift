//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController, ColorWheelDelegate {
    private var colorWheel: ColorWheel!

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        let colorWheelPos = CGRect(x: 50, y: 50, width: 300, height: 300)
        colorWheel = CGColorWheel(frame: colorWheelPos)
        colorWheel.delegate = self
        colorWheel.backgroundColor = .black
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
        colorWheel.brightness = CGFloat(sender.value)
    }
}

public protocol ColorWheelDelegate: class {
    func didSelect(color: UIColor)
}

public class RotatingColorWheel: CGColorWheel {
    private var rotateRecognizer: UIRotationGestureRecognizer!
    private var originalRotation: CGFloat = 2 * .pi
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareRotationRecognizer()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareRotationRecognizer()
    }
    
    @objc func didRotate(recognizer: UIRotationGestureRecognizer) {
        let newRotation = max(0, min(2 * .pi, originalRotation + recognizer.rotation))
        if recognizer.state == .changed {
            transform = CGAffineTransform(rotationAngle: newRotation)
            brightness = newRotation / (2 * .pi)
        } else if recognizer.state == .ended {
            originalRotation = newRotation
        }
    }
    
    public override func didMoveToSuperview() {
        superview?.backgroundColor = UIColor.black
    }
    
    private func prepareRotationRecognizer() {
        backgroundColor = UIColor.clear
        rotateRecognizer = UIRotationGestureRecognizer()
        addGestureRecognizer(rotateRecognizer)
        rotateRecognizer.addTarget(self, action: #selector(didRotate(recognizer:)))
    }
}

public class CGColorWheel: ColorWheel {
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
    }
    
    override open func layoutSubviews() {
        // nothing here
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.saveGState()
        (0...100).filter { $0 % 10 == 0 }.forEach { dist in
            (0..<360).filter { $0 % 10 == 0 }.forEach { deg in
                let distance = 1 - sin(CGFloat(dist) / 100 * .pi / 3)
                drawCircles(in: rect, of: context, deg: CGFloat(deg), distance: distance)
            }
        }
        drawCircles(in: rect, of: context, deg: 0, distance: 0)
        context.restoreGState()
    }
    
    override func updateBrightness() {
        setNeedsDisplay()
    }
    
    func drawCircles(in rect: CGRect, of context: CGContext, deg: CGFloat, distance: CGFloat) {
        let circleRadius = radius(deg: deg, distance: distance)
        let center = position(in: rect, deg: deg, distance: distance, circleRadius: circleRadius)
        let circleColor = color(deg: deg, distance: distance)
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
}

public class ColorWheel: UIView {
    public weak var delegate: ColorWheelDelegate?
    public var padding: CGFloat = 12.0
    public var brightness: CGFloat = 1.0 {
        didSet { updateBrightness() }
    }
    
    private var maxCircleRadius: CGFloat = 15.0
    private var tapRecognizer: UITapGestureRecognizer!
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareTapRecognizer()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareTapRecognizer()
    }
    
    override open func layoutSubviews() {
        print("laying out now")
        layer.sublayers?.removeAll()
        
        (0...100).filter { $0 % 10 == 0 }.forEach { dist in
            (0..<360).filter { $0 % 10 == 0 }.forEach { deg in
                let distance = 1 - sin(CGFloat(dist) / 100 * .pi / 3)
                drawCircle(deg: CGFloat(deg), distance: distance)
            }
        }
        drawCircle(deg: 0, distance: 0)
    }
    
    @objc func didRegisterTap(recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)
        let distance = sqrt(pow(touchPoint.x - wheelCenter.x, 2) + pow(touchPoint.y - wheelCenter.y, 2))
        let normalizedDistance = distance / radius
        
        guard normalizedDistance <= 1.0 else { return }
        
        let angle = angleToPoint(center: wheelCenter, pointOnCircle: touchPoint)
        let tappedColor = color(deg: angle, distance: normalizedDistance)
        delegate?.didSelect(color: tappedColor)
    }
    
    func adjustedAngleToPoint(center: CGPoint, pointOnCircle: CGPoint, distance: CGFloat) -> CGFloat {
        print("with x: \(-180 * acos(pointOnCircle.x / (center.x + distance * radius)) - 45 * distance * .pi)")
        print("with y: \(-180 * asin(pointOnCircle.y / (center.y + distance * radius)) - 45 * distance * .pi)")
        return -180 * acos(pointOnCircle.x / (center.x + distance * radius)) - 45 * distance * .pi
    }
    
    func angleToPoint(center: CGPoint, pointOnCircle: CGPoint) -> CGFloat {
        let originX = pointOnCircle.x - center.x
        let originY = pointOnCircle.y - center.y
        var radians = atan2(originY, originX) - .pi / 4
        
        while radians < 0 {
            radians += CGFloat(2 * Double.pi)
        }
        
        print("degree: \((radians + .pi) * 180 / .pi)")
        
        return (radians + .pi) * 180 / .pi
    }
    
    func updateBrightness() {
        layer.sublayers?.forEach { layer in
            guard let circle = layer as? CAShapeLayer else { return }
            circle.fillColor = color(circle.fillColor!, with: brightness)
        }
    }
}

fileprivate extension ColorWheel {
    var radius: CGFloat {
        return min(bounds.size.width, bounds.size.height) / 2 - padding
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
    
    func drawCircle(deg: CGFloat, distance: CGFloat) {
        let circleRadius = radius(deg: deg, distance: distance)
        let circle = CAShapeLayer()
        let rect = CGRect(x: 0, y: 0, width: circleRadius, height: circleRadius)
        let path: UIBezierPath = UIBezierPath(roundedRect: rect, cornerRadius: circleRadius)
        circle.path = path.cgPath
        circle.position = position(in: rect, deg: deg, distance: distance, circleRadius: circleRadius)
        circle.fillColor = color(deg: deg, distance: distance).cgColor
        layer.addSublayer(circle)
    }
    
    func color(_ color: CGColor, with brightness: CGFloat) -> CGColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0
        UIColor(cgColor: color).getHue(&hue, saturation: &saturation, brightness: nil, alpha: nil)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1).cgColor
    }
    
    func radius(deg: CGFloat, distance: CGFloat) -> CGFloat {
        guard distance > 0 else { return 4 * 4 }
        return max(4, maxCircleRadius * sin(distance))
    }
    
    func position(in rect: CGRect, deg: CGFloat, distance: CGFloat, circleRadius: CGFloat) -> CGPoint {
        let center = CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        let rad = (deg + distance * 45) / 180 * .pi
        let x = center.x + (radius - padding) * distance * cos(-rad)
        let y = center.y + (radius - padding) * distance * sin(-rad)
        return CGPoint(x: x, y: y)
    }
    
    func color(deg: CGFloat, distance: CGFloat) -> UIColor {
        return UIColor(hue: deg / 360, saturation: distance, brightness: brightness, alpha: 1)
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()

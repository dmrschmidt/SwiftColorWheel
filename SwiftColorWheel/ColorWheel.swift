import UIKit

public protocol ColorWheelDelegate: class {
    func didSelect(color: UIColor)
}

public class ColorWheel: UIView {
    public weak var delegate: ColorWheelDelegate?

    @objc public dynamic var brightness: CGFloat { didSet { wheelLayer.brightness = brightness } }
    public var padding: CGFloat = 12.0 { didSet { setNeedsDisplay() } }
    public var centerRadius: CGFloat = 4.0 { didSet { setNeedsDisplay() } }
    public var minCircleRadius: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    public var maxCircleRadius: CGFloat = 6.0 { didSet { setNeedsDisplay() } }
    public var innerPadding: CGFloat = 2 { didSet { setNeedsDisplay() } }
    public var shiftDegree: CGFloat = 40 { didSet { setNeedsDisplay() } }
    public var density: CGFloat = 0.8 { didSet { setNeedsDisplay() } }

    private let normalizedRadius: CGFloat = 1.0

    fileprivate var wheelLayer: ColorWheelLayer! {
        return layer as? ColorWheelLayer
    }

    private var tapRecognizer: UITapGestureRecognizer!

    public required init?(coder aDecoder: NSCoder) {
        brightness = 1.0
        super.init(coder: aDecoder)

        layer.contentsScale = UIScreen.main.scale
        prepareTapRecognizer()
        contentMode = .redraw
    }

    public override init(frame: CGRect) {
        brightness = 1.0
        super.init(frame: frame)

        layer.contentsScale = UIScreen.main.scale
        prepareTapRecognizer()
        contentMode = .redraw
    }

    override public class var layerClass: AnyClass {
        return ColorWheelLayer.self
    }

    // taken from: https://stackoverflow.com/questions/14192816/create-a-custom-animatable-property/44961463#44961463
    // backgroundColor is simply a "placeholder" to get the UIView.animate() properties
    override public func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == #keyPath(ColorWheelLayer.brightness),
           let action = action(for: layer, forKey: #keyPath(backgroundColor)) as? CAAnimation {

            let animation = CABasicAnimation()
            animation.keyPath = #keyPath(ColorWheelLayer.brightness)
            animation.fromValue = wheelLayer.brightness
            animation.toValue = brightness
            animation.beginTime = action.beginTime
            animation.duration = action.duration
            animation.speed = action.speed
            animation.timeOffset = action.timeOffset
            animation.repeatCount = action.repeatCount
            animation.repeatDuration = action.repeatDuration
            animation.autoreverses = action.autoreverses
            animation.fillMode = action.fillMode
            animation.timingFunction = action.timingFunction
            animation.delegate = action.delegate
            self.layer.add(animation, forKey: #keyPath(ColorWheelLayer.brightness))
        }
        return super.action(for: layer, forKey: event)
    }

    public func normalizedDistanceFromCenter(to touchPoint: CGPoint) -> CGFloat {
        let distance = sqrt(pow(touchPoint.x - wheelCenter.x, 2) + pow(touchPoint.y - wheelCenter.y, 2))
        return distance / wheelLayer.radius(in: bounds)
    }

    @objc func didRegisterTap(recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)
        let distance = normalizedDistanceFromCenter(to: touchPoint)
        guard distance <= normalizedRadius else { return }

        let angle = adjustedAngleTo(center: wheelCenter, pointOnCircle: touchPoint, distance: distance)
        let tappedColor = wheelLayer.color(at: angle, distance: distance)
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

    var wheelCenter: CGPoint {
        return CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
    }

    func prepareTapRecognizer() {
        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapRecognizer)
        tapRecognizer.addTarget(self, action: #selector(didRegisterTap(recognizer:)))
    }
}

import UIKit

enum RotationDirection: CGFloat {
    case none = 0
    case clockwise = 1
    case counterClockwise = -1
}

/**
 Rotatable color wheel picker.
 This is a subclass of `ColorWheel`. It adds two `UIGestureRecognizeras` to itself.
 Those allow one-finger and two-finger circular rotation to adjust the overall
 brightness of the colors.
 */
public class RotatingColorWheel: ColorWheel, CAAnimationDelegate {
    public private(set) var panRecognizer: UIPanGestureRecognizer!
    public private(set) var rotateRecognizer: UIRotationGestureRecognizer!

    private let defaultGestureHandler: DefaultWheelGestureHandler

    private var rotationArch: CGFloat = 2 * .pi
    private var lastDirection: RotationDirection = .none
    private var lastAngle: CGFloat = 2 * .pi
    private var angleDeltas: [CGFloat] = [0, 0, 0]
    private var timeDeltas: [TimeInterval] = [0, 0, 0]
    private let maxRotationSpeed: CGFloat = 0.7
    private let minimumSpeedThreshold: CGFloat = 0.06
    private let rotationAnimationDuration = 0.5

    public required init?(coder aDecoder: NSCoder) {
        defaultGestureHandler = DefaultWheelGestureHandler()
        super.init(coder: aDecoder)
        prepareRotationRecognizers()
    }

    public override init(frame: CGRect) {
        defaultGestureHandler = DefaultWheelGestureHandler()
        super.init(frame: frame)
        prepareRotationRecognizers()
    }

    public var isAnimating: Bool {
        return layer.animationKeys()?.isEmpty ?? false
    }

    @objc func didRotate(recognizer: UIRotationGestureRecognizer) {
        let newRotationArch = rotationArch + recognizer.rotation
        if recognizer.state == .changed {
            rotate(to: dampened(rotation: newRotationArch))
        } else if recognizer.state == .ended {
            rotationArch = newRotationArch
            continueAnimationMotionOrSnapBackIfOutOfRange(velocity: recognizer.velocity)
        } else if recognizer.state == .cancelled {
            continueAnimationMotionOrSnapBackIfOutOfRange(velocity: recognizer.velocity)
        }
    }

    func angleDelta(_ newAngle: CGFloat, _ oldAngle: CGFloat) -> CGFloat {
        return abs((abs(newAngle) - abs(oldAngle))) * movementDirection(newAngle, oldAngle).rawValue
    }

    func movementDirection(_ newAngle: CGFloat, _ oldAngle: CGFloat) -> RotationDirection {
        if newAngle < 0 && oldAngle > 0 && abs(newAngle) > .pi / 2 {
            return .clockwise
        } else if newAngle > 0 && oldAngle < 0 && abs(newAngle) > .pi / 2 {
            return .counterClockwise
        } else if newAngle > oldAngle {
            return .clockwise
        } else {
            return .counterClockwise
        }
    }

    func dampened(rotation: CGFloat) -> CGFloat {
        if rotation < 0 {
            let minValue: CGFloat = -(.pi)
            let undampenedDelta = max(minValue, rotation)
            let progress = abs(undampenedDelta / .pi)
            let dampenedProgress = sin(sqrt(progress) * (.pi / 2))
            return dampenedProgress * (-(.pi / 8))
        } else if rotation > 2 * .pi {
            let maxValue: CGFloat = 2 * .pi + .pi
            let undampenedDelta = min(maxValue, rotation) - 2 * .pi
            let progress = undampenedDelta / .pi
            let dampenedProgress = sin(sqrt(progress) * (.pi / 2))
            return 2 * .pi + dampenedProgress * (.pi / 8)
        }
        return rotation
    }

    @objc func didPan(recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: superview!)
        let center = convert(wheelCenter, to: superview!)
        let angle = angleTo(center: center, pointOnCircle: touchPoint)

        let newRotationArch = rotationArch + angleDelta(angle, lastAngle)
        trackAngleTravelled(delta: angleDelta(angle, lastAngle))
        if recognizer.state == .began {
            angleDeltas = [0, 0, 0]
            timeDeltas = [0, 0, 0]
            lastAngle = angle
        } else if recognizer.state == .changed {
            rotate(to: dampened(rotation: newRotationArch))
            lastDirection = movementDirection(angle, lastAngle)
            lastAngle = angle
            rotationArch = newRotationArch
        } else if recognizer.state == .ended {
            rotationArch = newRotationArch
            continueAnimationMotionOrSnapBackIfOutOfRange(velocity: radialSpeed(direction: lastDirection))
        } else if recognizer.state == .cancelled {
            continueAnimationMotionOrSnapBackIfOutOfRange(velocity: radialSpeed(direction: lastDirection))
        }
    }

    func trackAngleTravelled(delta: CGFloat) {
        angleDeltas.append(abs(delta))
        timeDeltas.append(Date().timeIntervalSince1970)
        angleDeltas.remove(at: 0)
        timeDeltas.remove(at: 0)
    }

    func radialSpeed(direction: RotationDirection) -> CGFloat {
        let distance: CGFloat = abs(angleDeltas.reduce(0, +))
        let timeDelta: CGFloat = CGFloat(timeDeltas.last! - timeDeltas.first!) * 10
        return min(maxRotationSpeed, distance / timeDelta) * direction.rawValue
    }

    func isOutOfSpinRange() -> Bool {
        return rotationArch < 0 || rotationArch > 2 * .pi
    }

    func continueAnimationMotionOrSnapBackIfOutOfRange(velocity: CGFloat) {
        if isOutOfSpinRange() {
            animateSpinBackMotion()
        } else if abs(velocity) > minimumSpeedThreshold {
            let deceleration: CGFloat = 0.1 // rad/s^2
            var distance = pow(velocity, 2) / (2 * deceleration)
            while distance >= .pi { distance -= .pi / 8 }
            let targetRotationArch = min(2 * .pi, max(0, rotationArch + distance * (velocity > 0 ? 1 : -1)))
            let targetRotationTransform = CATransform3DRotate(CATransform3DIdentity, targetRotationArch, 0, 0, 1)
            let targetBrightness = targetRotationArch / (2 * .pi)

            UIView.animate(withDuration: rotationAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.brightness = targetBrightness
                self.layer.transform = targetRotationTransform
            })

            brightness = targetBrightness
            rotationArch = targetRotationArch
        }
    }

    private func prepareRotationRecognizers() {
        defaultGestureHandler.colorWheel = self
        rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(recognizer:)))
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(recognizer:)))
        rotateRecognizer.delegate = defaultGestureHandler
        panRecognizer.delegate = defaultGestureHandler
        addGestureRecognizer(rotateRecognizer)
        addGestureRecognizer(panRecognizer)
    }
}

// MARK: - CAAnimationDelegate

extension RotatingColorWheel {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isOutOfSpinRange() {
            animateSpinBackMotion()
        }
    }
}

// MARK: - Private

fileprivate extension RotatingColorWheel {
    func animateSpinBackMotion() {
        let targetRotationArch: CGFloat = rotationArch < 0 ? 0 : 2 * .pi
        let spring = CASpringAnimation(keyPath: "transform")
        spring.damping = 20
        spring.stiffness = 1000
        spring.fromValue = NSValue(caTransform3D: layer.transform)
        // probably CATransform3DIdentity is enough here, but does it result in the same layer.transform?
        spring.toValue = NSValue(caTransform3D: CATransform3DRotate(CATransform3DIdentity, targetRotationArch, 0, 0, 1))
        spring.duration = spring.settlingDuration
        layer.transform = CATransform3DRotate(CATransform3DIdentity, targetRotationArch, 0, 0, 1)
        layer.add(spring, forKey: "transformAnimation")
        rotationArch = targetRotationArch
        brightness = targetRotationArch / (2 * .pi)
    }

    func rotate(to radians: CGFloat) {
        transform = CGAffineTransform(rotationAngle: radians)
        let mappedBrightness = radians / (2 * .pi)
        guard mappedBrightness >= 0 && mappedBrightness <= 1.0 else { return }
        brightness = mappedBrightness
    }
}

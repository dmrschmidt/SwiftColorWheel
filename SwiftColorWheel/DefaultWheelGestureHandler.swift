import Foundation
import UIKit

class DefaultWheelGestureHandler: NSObject, UIGestureRecognizerDelegate {
    weak var colorWheel: RotatingColorWheel?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let colorWheel = colorWheel else { return false }

        switch gestureRecognizer {
        case colorWheel.panRecognizer: return handlePanGesture(colorWheel.panRecognizer)
        case colorWheel.rotateRecognizer: return handleRotateGesture(colorWheel.rotateRecognizer)
        default: return true // any other recognizer should deal with animation etc. itself
        }
    }

    private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard let colorWheel = colorWheel else { return true }

        // since the view is rotated, the coordinates are also "rotated"
        let rotatedTouchPoint = gestureRecognizer.location(in: colorWheel)
        let distance = colorWheel.normalizedDistanceFromCenter(to: rotatedTouchPoint)
        let isWithinRadius = distance <= 1.0

        return isWithinRadius && !colorWheel.isAnimating
    }

    private func handleRotateGesture(_ gestureRecognizer: UIRotationGestureRecognizer) -> Bool {
        guard let colorWheel = colorWheel else { return true }

        // since the view is rotated, the coordinates are also "rotated"
        let rotatedTouchPointA = gestureRecognizer.location(ofTouch: 0, in: colorWheel)
        let rotatedTouchPointB = gestureRecognizer.location(ofTouch: 1, in: colorWheel)
        let distanceA = colorWheel.normalizedDistanceFromCenter(to: rotatedTouchPointA)
        let distanceB = colorWheel.normalizedDistanceFromCenter(to: rotatedTouchPointB)
        let areWithinRadius = distanceA <= 1.0 && distanceB <= 1.0

        return areWithinRadius && !colorWheel.isAnimating
    }
}

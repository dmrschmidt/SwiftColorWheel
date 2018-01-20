import Foundation
import UIKit

public class ColorWheelViewOld: UIView {
    override open func layoutSubviews() {
        let radius: CGFloat = 100
        let circle = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: radius, height: radius), cornerRadius: radius)
        circle.path = path.cgPath
        circle.position = center
        circle.fillColor = UIColor.green.cgColor
        layer.addSublayer(circle)
    }
}

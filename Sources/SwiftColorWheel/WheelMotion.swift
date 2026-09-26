import Foundation

/// Scroll-view physics bent round a wheel: rubber band past the ends, friction, spring back.
/// One full turn is the whole brightness range.
struct WheelMotion: Equatable, Sendable {
    var tuning = ColorWheelConfiguration.Motion()
    private(set) var rotation: Double
    private(set) var velocity = 0.0
    private var finger = 0.0

    // UIScrollView's rubber-band constant
    private static let pull = 0.55
    private static let restSpeed = 0.02, restDistance = 0.002

    init(rotation: Double = .fullTurn) {
        self.rotation = rotation
    }

    var brightness: Double { Self.clamp(rotation) / .fullTurn }
    var overshoot: Double { rotation - Self.clamp(rotation) }
    var isAtRest: Bool { abs(velocity) < Self.restSpeed && abs(overshoot) < Self.restDistance }

    /// Where a coast from here will end.
    var restingRotation: Double {
        Self.clamp(overshoot != 0 ? rotation : rotation + velocity / tuning.friction)
    }

    mutating func jump(to rotation: Double) {
        self.rotation = rotation
        velocity = 0
    }

    mutating func grab() {
        velocity = 0
        let past = abs(overshoot)
        finger = rotation + (overshoot < 0 ? -1 : 1) * (unband(past) - past)
    }

    mutating func drag(by delta: Double, over interval: TimeInterval) {
        finger += delta
        let past = finger - Self.clamp(finger)
        let next = Self.clamp(finger) + (past < 0 ? -1 : 1) * band(abs(past))
        velocity = 0.6 * (next - rotation) / max(0.004, interval) + 0.4 * velocity
        rotation = next
    }

    mutating func release(afterStillFor idle: TimeInterval) {
        velocity = idle > 0.09 ? 0 : min(25, max(-25, velocity))
    }

    mutating func step(_ interval: TimeInterval) {
        let dt = min(0.032, max(0, interval))
        if overshoot != 0 {
            velocity += (-tuning.stiffness * overshoot - 2 * tuning.stiffness.squareRoot() * velocity) * dt
        } else {
            velocity *= exp(-tuning.friction * dt)
        }
        rotation += velocity * dt
        if isAtRest { jump(to: Self.clamp(rotation)) }
    }

    private static func clamp(_ rotation: Double) -> Double { min(.fullTurn, max(0, rotation)) }

    private func band(_ past: Double) -> Double {
        let limit = tuning.maxOvershoot
        return limit > 0 ? (1 - 1 / (past * Self.pull / limit + 1)) * limit : 0
    }

    private func unband(_ shown: Double) -> Double {
        let limit = tuning.maxOvershoot
        return limit > 0 ? limit / Self.pull * (1 / (1 - min(shown, limit * 0.99) / limit) - 1) : 0
    }
}

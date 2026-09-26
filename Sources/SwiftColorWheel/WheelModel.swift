import SwiftUI

/// The wheel's state: pick, rotation, touch and loupe.
@MainActor @Observable
final class WheelModel {
    private(set) var geometry = WheelGeometry()
    private(set) var motion = WheelMotion()
    private(set) var selected = 0
    private(set) var loupeCenter = CGPoint.zero
    private(set) var isLoupeHidden = false
    private(set) var isAnimating = false

    /// The last few colours written to the binding, to tell our own echoes from a colour set
    /// outside. More than one, because an echo can come back a frame or two late.
    @ObservationIgnored private(set) var emitted: [HSBColor] = []
    @ObservationIgnored var holdsNextEmission = false
    @ObservationIgnored private var configuration = ColorWheelConfiguration()
    @ObservationIgnored private var phase = Phase.idle
    @ObservationIgnored private var lastTick: Date?
    /// The loupe is hidden and waiting to be moved.
    @ObservationIgnored private var loupeIsStale = false
    @ObservationIgnored private var loupeHiddenAt = Date.distantPast

    private enum Phase {
        case idle
        case touching(Touch)
        case coasting
        case spinning(Spin)
    }

    private struct Touch {
        var start: CGPoint
        var angle: Double
        var turning: Bool
        var moved: Date
    }

    private struct Spin {
        var began: Date?
        var from: Double, to: Double
        var loupeAngle: Double, loupeSweep: Double
        var loupeReach: CGFloat, loupeReachEnd: CGFloat
    }

    private static let slop: CGFloat = 6
    private static let spinDuration = 0.7
    private static let loupeHideDuration = 0.3

    var color: HSBColor {
        guard geometry.cells.indices.contains(selected) else { return HSBColor(hue: 0, saturation: 0, brightness: motion.brightness) }
        let cell = geometry.cells[selected]
        return HSBColor(hue: cell.hue, saturation: cell.saturation, brightness: motion.brightness)
    }

    func didEmit(_ color: HSBColor) {
        emitted = emitted.suffix(7) + [color]
    }

    // MARK: Layout

    func layout(side: CGFloat, configuration: ColorWheelConfiguration, showing color: HSBColor) {
        let shown = geometry.cells.isEmpty ? color : self.color
        self.configuration = configuration
        motion.tuning = configuration.motion
        geometry = WheelGeometry(side: side, configuration: configuration)
        selected = geometry.nearestCell(to: shown)
        if case .idle = phase {
            motion.jump(to: shown.brightness * .fullTurn)
            loupeCenter = loupeSpot(at: motion.rotation)
        }
    }

    // MARK: Colours from outside

    func spin(to color: HSBColor) {
        guard !geometry.cells.isEmpty else { return }
        settle()
        selected = geometry.nearestCell(to: color)
        let target = color.brightness * .fullTurn, end = loupeSpot(at: target), center = geometry.center
        let startAngle = atan2(loupeCenter.y - center.y, loupeCenter.x - center.x)
        var sweep = atan2(end.y - center.y, end.x - center.x) - startAngle
        sweep += .fullTurn * ((target - motion.rotation - sweep) / .fullTurn).rounded()   // the turn nearest the wheel's own
        phase = .spinning(Spin(from: motion.rotation, to: target, loupeAngle: startAngle, loupeSweep: sweep,
                               loupeReach: hypot(loupeCenter.x - center.x, loupeCenter.y - center.y),
                               loupeReachEnd: hypot(end.x - center.x, end.y - center.y)))
        isLoupeHidden = false
        loupeIsStale = false
        animate()
    }

    func nudgeBrightness(by amount: Double) {
        var color = self.color
        color.brightness = min(1, max(0, color.brightness + amount))
        spin(to: color)
    }

    // MARK: Touch

    func touch(at point: CGPoint, now: Date = .now) {
        guard case .touching(var touch) = phase else {
            let caught = isAnimating
            settle()
            motion.grab()
            if caught { hideLoupe(now) }
            phase = .touching(Touch(start: point, angle: angle(to: point), turning: caught, moved: now))
            return
        }
        let angle = angle(to: point), delta = atan2(sin(angle - touch.angle), cos(angle - touch.angle))
        touch.angle = angle
        touch.turning = touch.turning || hypot(point.x - touch.start.x, point.y - touch.start.y) > Self.slop
        if touch.turning, configuration.motion.isEnabled {
            hideLoupe(now)
            motion.drag(by: delta, over: now.timeIntervalSince(touch.moved))
            touch.moved = now
        }
        phase = .touching(touch)
    }

    func lift(at point: CGPoint, now: Date = .now) {
        guard case .touching(let touch) = phase else { return }
        phase = .idle
        guard touch.turning, configuration.motion.isEnabled else {
            selected = geometry.nearestCell(to: point, rotation: motion.rotation)
            loupeCenter = loupeSpot(at: motion.rotation)
            return
        }
        motion.release(afterStillFor: now.timeIntervalSince(touch.moved))
        phase = .coasting
        animate()
    }

    // MARK: Frames

    func tick(_ now: Date) {
        let interval = lastTick.map { now.timeIntervalSince($0) } ?? 1 / 60
        lastTick = now
        switch phase {
        case .coasting:
            motion.step(interval)
            if !loupeIsStale || now.timeIntervalSince(loupeHiddenAt) > Self.loupeHideDuration {
                loupeIsStale = false
                loupeCenter = loupeSpot(at: motion.restingRotation)
            }
            isLoupeHidden = loupeIsStale || abs(motion.velocity) > 0.5 || abs(motion.overshoot) > 0.02
            if motion.isAtRest, !loupeIsStale { settle() }
        case .spinning(var spin):
            let began = spin.began ?? now
            spin.began = began
            let progress = min(1, max(0, now.timeIntervalSince(began) / Self.spinDuration)), eased = 1 - pow(1 - progress, 3)
            motion.jump(to: spin.from + (spin.to - spin.from) * eased)
            let angle = spin.loupeAngle + spin.loupeSweep * eased, reach = spin.loupeReach + (spin.loupeReachEnd - spin.loupeReach) * eased
            loupeCenter = CGPoint(x: geometry.center.x + reach * cos(angle), y: geometry.center.y + reach * sin(angle))
            phase = .spinning(spin)
            if progress >= 1 { settle() }
        case .idle, .touching:
            isAnimating = false
        }
    }

    // MARK: Private

    private func animate() {
        lastTick = nil
        isAnimating = true
    }

    private func settle() {
        phase = .idle
        isAnimating = false
    }

    private func hideLoupe(_ now: Date) {
        if !isLoupeHidden { loupeHiddenAt = now }
        loupeIsStale = true
        isLoupeHidden = true
    }

    private func angle(to point: CGPoint) -> Double {
        atan2(point.y - geometry.center.y, point.x - geometry.center.x)
    }

    private func loupeSpot(at rotation: Double) -> CGPoint {
        guard geometry.cells.indices.contains(selected) else { return geometry.center }
        let cell = geometry.cells[selected], loupeRadius = (configuration.loupe?.diameter ?? 0) / 2
        return geometry.loupeCenter(beside: geometry.position(of: cell, rotation: rotation), extent: geometry.extent(of: cell),
                                    loupeRadius: loupeRadius, keepingClearOfCenterBy: geometry.hole + loupeRadius + 4)
    }
}

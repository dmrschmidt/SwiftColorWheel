import SwiftUI
import Testing
@testable import SwiftColorWheel

@Suite struct LayoutTests {
    @Test func swatchesAreEveryHueAtEveryStrength() {
        let cells = ColorWheelLayout.swatches(.init(hues: 24, rings: 5)).cells(radius: 165)
        #expect(cells.count == 120)
        #expect(Set(cells.map(\.saturation)).count == 5)
    }

    @Test func dotsShrinkTowardACentreDot() throws {
        let cells = ColorWheelLayout.dots().cells(radius: 150)
        let centre = try #require(cells.last)
        #expect(centre.distance == 0)
        #expect(cells.count > 100)
        #expect(cells.allSatisfy { $0.distance <= 1 })
    }

    @Test func dotsMakeRoomForACentreViewOnlyWhenOneIsShown() {
        let open = WheelGeometry(side: 370, configuration: ColorWheelConfiguration(layout: .dots()))
        #expect(open.hole > 0)
        #expect(open.cells.allSatisfy { open.reach * $0.distance > open.hole })
        let closed = WheelGeometry(side: 370, configuration: ColorWheelConfiguration(layout: .dots(), showsCenter: false))
        #expect(closed.hole == 0)
        #expect(closed.cells.last?.distance == 0)
    }

    @Test func swatchesGrowInwardWhenNothingSitsInTheMiddle() {
        let open = WheelGeometry(side: 370, configuration: .underGlass)
        var bare = ColorWheelConfiguration.underGlass
        bare.showsCenter = false
        let filled = WheelGeometry(side: 370, configuration: bare)
        #expect(filled.cells.count == open.cells.count)
        #expect(filled.hole < open.hole / 2)
    }

    /// Dots are centred on their ring, so the outer ring is pulled in by a dot's radius.
    @Test func noDotReachesPastTheWheelsRadius() {
        let geometry = WheelGeometry(side: 370, configuration: ColorWheelConfiguration(layout: .dots()))
        for cell in geometry.cells {
            guard case .dot(let dotRadius) = cell.shape else { continue }
            #expect(geometry.reach * cell.distance + dotRadius <= geometry.radius + 0.001)
        }
    }

    @Test(arguments: [ColorWheelConfiguration.underGlass, .plate, .classic])
    func everyCellFindsItselfByItsOwnColour(configuration: ColorWheelConfiguration) {
        let geometry = WheelGeometry(side: 370, configuration: configuration)
        for (index, cell) in geometry.cells.enumerated() where cell.saturation > 0 {
            let found = geometry.nearestCell(to: HSBColor(hue: cell.hue, saturation: cell.saturation, brightness: 1))
            #expect(geometry.cells[found] == cell, "cell \(index)")
        }
    }
}

@Suite struct LoupeTests {
    /// For every cell at every turn of the wheel: inside the frame, off the centre, off the pick.
    @Test(arguments: [ColorWheelConfiguration.underGlass, .plate, ColorWheelConfiguration(layout: .dots())])
    func loupeStaysInFrameAndClearOfCentreAndPick(configuration: ColorWheelConfiguration) {
        let geometry = WheelGeometry(side: 370, configuration: configuration)
        let loupeRadius: CGFloat = 39, keepOut = geometry.hole + loupeRadius + 4
        var misplaced = 0
        for rotation in stride(from: 0, through: Double.fullTurn, by: 0.05) {
            for cell in geometry.cells {
                let pick = geometry.position(of: cell, rotation: rotation), extent = geometry.extent(of: cell)
                let spot = geometry.loupeCenter(beside: pick, extent: extent, loupeRadius: loupeRadius, keepingClearOfCenterBy: keepOut)
                let inFrame = (27 ... 343).contains(spot.x) && (27 ... 343).contains(spot.y)
                let offCentre = hypot(spot.x - geometry.center.x, spot.y - geometry.center.y) >= keepOut
                let offPick = hypot(spot.x - pick.x, spot.y - pick.y) >= loupeRadius + extent
                if !(inFrame && offCentre && offPick) { misplaced += 1 }
            }
        }
        #expect(misplaced == 0)
    }
}

@Suite struct MotionTests {
    private func coast(_ motion: inout WheelMotion) {
        for _ in 0 ..< 2000 where !motion.isAtRest { motion.step(1.0 / 60) }
    }

    @Test func aGentleFlingRestsWhereItSaidItWould() {
        var motion = WheelMotion(rotation: 4)
        motion.grab()
        for _ in 0 ..< 6 { motion.drag(by: -0.06, over: 0.016) }
        motion.release(afterStillFor: 0)
        let predicted = motion.restingRotation
        coast(&motion)
        #expect(motion.isAtRest)
        #expect(abs(motion.rotation - predicted) < 0.05)
        #expect(motion.rotation < 4 - 0.36)
    }

    @Test func aHardFlingOvershootsTheEndAndComesBackToIt() {
        var motion = WheelMotion(rotation: 3)
        motion.grab()
        for _ in 0 ..< 8 { motion.drag(by: -0.3, over: 0.016) }
        motion.release(afterStillFor: 0)
        #expect(motion.restingRotation == 0)
        var furthest = 0.0
        for _ in 0 ..< 2000 where !motion.isAtRest {
            motion.step(1.0 / 60)
            furthest = min(furthest, motion.overshoot)
        }
        #expect(furthest < -0.05)
        #expect(motion.rotation == 0)
        #expect(motion.brightness == 0)
    }

    @Test func draggingPastTheEndRubberBands() {
        var motion = WheelMotion(rotation: .fullTurn)
        motion.grab()
        for _ in 0 ..< 100 { motion.drag(by: 0.1, over: 0.016) }
        #expect(motion.overshoot > 0.5)
        #expect(motion.overshoot < motion.tuning.maxOvershoot)
        #expect(motion.brightness == 1)
    }

    @Test func aFingerThatStoppedLetsGoOfAStillWheel() {
        var motion = WheelMotion(rotation: 3)
        motion.grab()
        motion.drag(by: 0.2, over: 0.016)
        motion.release(afterStillFor: 0.2)
        #expect(motion.velocity == 0)
    }
}

@Suite struct ColourTests {
    @Test func survivesTheTripThroughColor() {
        let colour = HSBColor(hue: 0.62, saturation: 0.7, brightness: 0.45)
        let back = HSBColor(colour.color)
        #expect(abs(back.hue - colour.hue) < 0.01)
        #expect(abs(back.saturation - colour.saturation) < 0.01)
        #expect(abs(back.brightness - colour.brightness) < 0.01)
    }

    @Test func rgbMatchesTheHueWheel() {
        let red = HSBColor(hue: 0, saturation: 1, brightness: 1).rgb
        #expect(red.red == 1 && red.green == 0 && red.blue == 0)
        let teal = HSBColor(hue: 0.5, saturation: 1, brightness: 0.5).rgb
        #expect(teal.red == 0 && teal.green == 0.5 && teal.blue == 0.5)
    }
}

@MainActor @Suite struct ModelTests {
    private let start = HSBColor(hue: 8.5 / 24, saturation: 0.8, brightness: 0.94)

    private func model(_ configuration: ColorWheelConfiguration = .underGlass) -> WheelModel {
        let model = WheelModel()
        model.layout(side: 370, configuration: configuration, showing: start)
        return model
    }

    /// Frames at 60 a second from `time` until the model stops asking for them.
    private func run(_ model: WheelModel, from time: inout Date) {
        for _ in 0 ..< 2000 where model.isAnimating {
            time += 1.0 / 60
            model.tick(time)
        }
    }

    @Test func opensOnTheColourItIsGiven() {
        let model = model()
        #expect(abs(model.color.hue - start.hue) < 0.001)
        #expect(model.color.saturation == start.saturation)
        #expect(abs(model.color.brightness - start.brightness) < 0.001)
        #expect(!model.isLoupeHidden)
    }

    @Test func aTapPicksTheCellUnderIt() throws {
        let model = model()
        let cell = try #require(model.geometry.cells.first { $0.saturation == 1 && abs($0.hue - 0.6) < 0.03 })
        let point = model.geometry.position(of: cell, rotation: model.motion.rotation)
        model.touch(at: point)
        model.lift(at: point)
        #expect(model.color.hue == cell.hue)
        #expect(model.color.saturation == 1)
        #expect(!model.isAnimating)
    }

    @Test func aDragHidesTheLoupeWhereItIsAndAFlingBringsItBackWhereTheWheelStops() {
        let model = model()
        var time = Date(timeIntervalSinceReferenceDate: 0)
        let home = model.loupeCenter, center = model.geometry.center
        model.touch(at: CGPoint(x: center.x + 120, y: center.y), now: time)
        for step in 1 ... 8 {
            time += 0.016
            let angle = -0.08 * Double(step)
            model.touch(at: CGPoint(x: center.x + 120 * cos(angle), y: center.y + 120 * sin(angle)), now: time)
            #expect(model.isLoupeHidden)
            #expect(model.loupeCenter == home)
        }
        model.lift(at: .zero, now: time)
        #expect(model.isAnimating)
        var shownAt: CGPoint?
        for _ in 0 ..< 2000 where model.isAnimating {
            time += 1.0 / 60
            model.tick(time)
            if !model.isLoupeHidden, shownAt == nil { shownAt = model.loupeCenter }
        }
        #expect(model.color.brightness < start.brightness - 0.1)
        #expect(!model.isLoupeHidden)
        let appeared = shownAt ?? .zero
        #expect(hypot(appeared.x - model.loupeCenter.x, appeared.y - model.loupeCenter.y) < 3)
    }

    @Test func aColourFromOutsideSpinsTheWheelToItWithTheLoupeInView() {
        let model = model()
        var time = Date(timeIntervalSinceReferenceDate: 0)
        let navy = HSBColor(hue: 15.5 / 24, saturation: 1, brightness: 0.3)
        model.spin(to: navy)
        #expect(model.isAnimating)
        var furthestJump: CGFloat = 0, last = model.loupeCenter
        for _ in 0 ..< 2000 where model.isAnimating {
            time += 1.0 / 60
            model.tick(time)
            #expect(!model.isLoupeHidden)
            furthestJump = max(furthestJump, hypot(model.loupeCenter.x - last.x, model.loupeCenter.y - last.y))
            last = model.loupeCenter
        }
        #expect(abs(model.color.hue - navy.hue) < 0.001)
        #expect(abs(model.color.brightness - 0.3) < 0.001)
        // no hop across the wheel
        #expect(furthestJump < 100)
    }

    @Test func aTouchCatchesAMovingWheelInsteadOfPicking() {
        let model = model()
        var time = Date(timeIntervalSinceReferenceDate: 0)
        model.spin(to: HSBColor(hue: 0.1, saturation: 1, brightness: 0.2))
        for _ in 0 ..< 10 {
            time += 1.0 / 60
            model.tick(time)
        }
        let picked = model.selected, point = CGPoint(x: 40, y: 185)
        model.touch(at: point, now: time)
        #expect(!model.isAnimating)
        model.lift(at: point, now: time)
        #expect(model.selected == picked)
        run(model, from: &time)
        #expect(!model.isLoupeHidden)
    }

    @Test func withTurningOffADragOnlyPicks() {
        var configuration = ColorWheelConfiguration.underGlass
        configuration.motion.isEnabled = false
        let model = model(configuration)
        model.touch(at: CGPoint(x: 300, y: 185))
        model.touch(at: CGPoint(x: 300, y: 100))
        model.lift(at: CGPoint(x: 300, y: 100))
        #expect(abs(model.color.brightness - start.brightness) < 0.001)
        #expect(!model.isAnimating)
        #expect(!model.isLoupeHidden)
    }
}

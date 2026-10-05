import SwiftUI

/// Where every cell is, for one size. Angles are screen angles; a cell sits at `rotation - cell.angle`.
struct WheelGeometry: Equatable, Sendable {
    var side: CGFloat = 0
    var radius: CGFloat = 0
    /// What a cell's `distance` is a fraction of.
    var reach: CGFloat = 0
    var cells: [WheelCell] = []
    var hole: CGFloat = 0

    var center: CGPoint { CGPoint(x: side / 2, y: side / 2) }

    init() {}

    init(side: CGFloat, configuration: ColorWheelConfiguration) {
        self.side = side
        radius = max(0, side / 2 - Self.margin(for: configuration))
        reach = max(0, radius - configuration.layout.overhang)
        cells = configuration.layout.cells(radius: reach, showsCenter: configuration.showsCenter)
        hole = max(0, reach * configuration.layout.hole(showsCenter: configuration.showsCenter) - 1.5)
    }

    private static func margin(for configuration: ColorWheelConfiguration) -> CGFloat {
        if configuration.ticks != nil { return Self.tickReach + 9 }
        if let dome = configuration.dome { return dome.overhang + 9 }
        return 12
    }

    static let tickStart: CGFloat = 14, tickEnd: CGFloat = 19, tickLongEnd: CGFloat = 26, tickReach: CGFloat = 28

    func position(of cell: WheelCell, rotation: Double) -> CGPoint {
        let angle = rotation - cell.angle, distance = reach * cell.distance
        return CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
    }

    func path(for cell: WheelCell, rotation: Double, grow: CGFloat = 0) -> Path {
        switch cell.shape {
        case .dot(let dotRadius):
            let center = position(of: cell, rotation: rotation), r = dotRadius + grow
            return Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
        case .wedge(let inner, let outer, let halfAngle, let inset, _):
            let angle = rotation - cell.angle, gap = inset - grow
            let near = max(0.5, radius * inner + gap), far = radius * outer - gap
            var path = Path()
            // clockwise: false runs clockwise on screen
            path.addArc(center: center, radius: far, startAngle: .radians(angle - halfAngle + gap / far),
                        endAngle: .radians(angle + halfAngle - gap / far), clockwise: false)
            path.addArc(center: center, radius: near, startAngle: .radians(angle + halfAngle - gap / near),
                        endAngle: .radians(angle - halfAngle + gap / near), clockwise: true)
            path.closeSubpath()
            return path
        }
    }

    func extent(of cell: WheelCell) -> CGFloat {
        switch cell.shape {
        case .dot(let dotRadius): dotRadius + 8
        case .wedge(let inner, let outer, let halfAngle, _, _): hypot(radius * (outer - inner) / 2, radius * cell.distance * halfAngle) + 6
        }
    }

    func nearestCell(to point: CGPoint, rotation: Double) -> Int {
        cells.indices.min { distance(point, position(of: cells[$0], rotation: rotation)) < distance(point, position(of: cells[$1], rotation: rotation)) } ?? 0
    }

    func nearestCell(to color: HSBColor) -> Int {
        func miss(_ cell: WheelCell) -> Double {
            let hue = abs(cell.hue - color.hue), turn = min(hue, 1 - hue)
            return pow(turn * 2 * min(cell.saturation, color.saturation), 2) + pow(cell.saturation - color.saturation, 2)
        }
        return cells.indices.min { miss(cells[$0]) < miss(cells[$1]) } ?? 0
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}

extension WheelGeometry {
    /// Tries outward first, then fans round both ways until the loupe is in frame and off the centre.
    func loupeCenter(beside pick: CGPoint, extent: CGFloat, loupeRadius: CGFloat, keepingClearOfCenterBy keepOut: CGFloat) -> CGPoint {
        let reach = loupeRadius + extent + 3
        let outward = atan2(pick.y - center.y, pick.x - center.x)
        let frame = (loupeRadius - 12) ... max(loupeRadius - 12, side - loupeRadius + 12)
        for turn in [0, 0.5, -0.5, 1, -1, 1.5, -1.5, 2, -2, 2.5, -2.5, .pi] {
            let spot = CGPoint(x: pick.x + reach * cos(outward + turn), y: pick.y + reach * sin(outward + turn))
            if frame.contains(spot.x), frame.contains(spot.y), distance(spot, center) >= keepOut { return spot }
        }
        return CGPoint(x: pick.x, y: pick.y - reach)
    }
}

import UIKit

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx*dx + dy*dy)
    }
}

extension CGPath {
    func forEach(_ body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { info, element in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    
    func points() -> [CGPoint] {
        var points: [CGPoint] = []
        self.forEach { element in
            switch element.type {
            case .moveToPoint, .addLineToPoint:
                points.append(element.points[0])
            case .addQuadCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
            case .addCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
                points.append(element.points[2])
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        return points
    }
}
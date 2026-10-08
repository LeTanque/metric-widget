import CoreGraphics
import SwiftUI

enum ChamferedRect {
    static let defaultChamfer: CGFloat = 12

    static func swiftUIPath(in rect: CGRect, chamfer: CGFloat) -> Path {
        Path(cgPath(in: rect, chamfer: chamfer, originAtBottom: false))
    }

    static func appKitPath(in rect: CGRect, chamfer: CGFloat) -> CGPath {
        cgPath(in: rect, chamfer: chamfer, originAtBottom: true)
    }

    private static func cgPath(in rect: CGRect, chamfer: CGFloat, originAtBottom: Bool) -> CGPath {
        let cut = min(max(chamfer, 0), min(rect.width, rect.height))
        let path = CGMutablePath()
        if originAtBottom {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

struct ChamferedRectangle: Shape {
    var chamfer: CGFloat = ChamferedRect.defaultChamfer

    func path(in rect: CGRect) -> Path {
        ChamferedRect.swiftUIPath(in: rect, chamfer: chamfer)
    }
}

extension View {
    func chamferedTileShape(
        chamfer: CGFloat = ChamferedRect.defaultChamfer,
        border: Color? = Color.white.opacity(0.22)
    ) -> some View {
        let shape = ChamferedRectangle(chamfer: chamfer)
        return clipShape(shape)
            .overlay {
                if let border {
                    shape.stroke(border, lineWidth: 1)
                }
            }
    }
}

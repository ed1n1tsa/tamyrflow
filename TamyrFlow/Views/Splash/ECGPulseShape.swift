import SwiftUI

/// Classic ECG pulse path (normalized to the provided reference silhouette).
struct ECGPulseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midY = rect.midY

        // Control points as fractions of width — matches the attached pulse art.
        func x(_ t: CGFloat) -> CGFloat { rect.minX + w * t }
        func y(_ dy: CGFloat) -> CGFloat { midY + h * dy }

        var path = Path()
        path.move(to: CGPoint(x: x(0.00), y: midY))
        path.addLine(to: CGPoint(x: x(0.18), y: midY))

        // Small P-wave
        path.addLine(to: CGPoint(x: x(0.24), y: y(-0.10)))
        path.addLine(to: CGPoint(x: x(0.30), y: y(0.08)))
        path.addLine(to: CGPoint(x: x(0.36), y: midY))

        // QRS complex
        path.addLine(to: CGPoint(x: x(0.42), y: midY))
        path.addLine(to: CGPoint(x: x(0.48), y: y(-0.46)))
        path.addLine(to: CGPoint(x: x(0.54), y: y(0.42)))
        path.addLine(to: CGPoint(x: x(0.60), y: midY))

        // T-wave
        path.addLine(to: CGPoint(x: x(0.68), y: midY))
        path.addLine(to: CGPoint(x: x(0.76), y: y(-0.18)))
        path.addLine(to: CGPoint(x: x(0.84), y: midY))

        path.addLine(to: CGPoint(x: x(1.00), y: midY))
        return path
    }
}

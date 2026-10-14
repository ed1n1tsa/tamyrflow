import SwiftUI

/// Animated brand splash (~2.8s): logo fade/scale → ECG draw → `onFinished`.
struct AnimatedSplashView: View {
    var onFinished: () -> Void

    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.90
    @State private var pulseProgress: CGFloat = 0
    @State private var didFinish = false

    /// Total sequence length requested by design.
    private let totalDuration: TimeInterval = 2.8
    private let logoDuration: TimeInterval = 0.85
    private let pulseStart: TimeInterval = 0.70
    private let pulseDuration: TimeInterval = 1.55

    var body: some View {
        GeometryReader { geo in
            let pulseWidth = min(geo.size.width * 0.62, 280)

            ZStack {
                Image("SplashBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    HStack(spacing: 12) {
                        Image("BrandLogoTF")
                            .resizable()
                            .renderingMode(.template)
                            .interpolation(.high)
                            .frame(width: 42, height: 47)
                            .foregroundStyle(.white)

                        Text("TAMYR FLOW")
                            .font(AppFont.interBold(28))
                            .tracking(2.0)
                            .foregroundStyle(.white)
                    }
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                    ECGPulseShape()
                        .trim(from: 0, to: pulseProgress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: pulseWidth, height: 56)
                        .opacity(logoOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        guard !didFinish else { return }

        withAnimation(.easeOut(duration: logoDuration)) {
            logoOpacity = 1
            logoScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pulseStart) {
            withAnimation(.easeInOut(duration: pulseDuration)) {
                pulseProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            guard !didFinish else { return }
            didFinish = true
            onFinished()
        }
    }
}

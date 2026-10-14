import SwiftUI

/// Search radar: center asset (12) + small (13) / large (14) orbs orbiting clockwise.
struct WatchSearchAnimationView: View {
    var isAnimating: Bool = true

    @State private var rotation: Double = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            Image("WatchSearchCenter")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .scaleEffect(pulse && isAnimating ? 1.04 : 1.0)
                .animation(
                    isAnimating
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )

            // Large orbs — outer ring
            ForEach(0..<4, id: \.self) { i in
                Image("WatchOrbLarge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .offset(y: -92)
                    .rotationEffect(.degrees(rotation + Double(i) * 90))
            }

            // Small orbs — inner ring, offset phase
            ForEach(0..<6, id: \.self) { i in
                Image("WatchOrbSmall")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .offset(y: -68)
                    .rotationEffect(.degrees(rotation * 1.15 + Double(i) * 60 + 20))
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            pulse = isAnimating
            guard isAnimating else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .onChange(of: isAnimating) { _, on in
            pulse = on
            if on {
                rotation = 0
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

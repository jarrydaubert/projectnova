import SwiftUI

// MARK: - PawNova Brand Colors (Aurora Theme)

extension Color {
    // Primary brand - Aurora palette (Purple + Mint)
    static let pawPrimary = Color(hex: "#8B5CF6")      // Violet - creative, magical
    static let pawSecondary = Color(hex: "#34D399")    // Mint - fresh, modern
    static let pawAccent = Color(hex: "#A78BFA")       // Light violet - highlights

    // Background colors - Deep space feel
    static let pawBackground = Color(hex: "#0F0F1A")   // Near black with purple tint
    static let pawCard = Color(hex: "#1A1A2E")         // Card background

    // Text colors
    static let pawTextPrimary = Color.white
    static let pawTextSecondary = Color(hex: "#A1A1AA")

    // Status colors
    static let pawSuccess = Color(hex: "#34D399")      // Mint (matches secondary)
    static let pawWarning = Color(hex: "#FBBF24")      // Yellow
    static let pawError = Color(hex: "#F87171")        // Soft red

    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - PawNova Gradients

extension LinearGradient {
    // Primary brand gradient - Purple to Mint
    static let pawPrimary = LinearGradient(
        colors: [Color.pawPrimary, Color.pawSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Button gradient - Mint to Purple (eye-catching CTAs)
    static let pawButton = LinearGradient(
        colors: [Color.pawSecondary, Color.pawPrimary],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Subtle card gradient
    static let pawCard = LinearGradient(
        colors: [Color.pawCard, Color.pawCard.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Success state
    static let pawSuccess = LinearGradient(
        colors: [Color.pawSecondary, Color.pawSecondary.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - iOS 18 MeshGradient

/// Rich 2D mesh gradient for immersive backgrounds (iOS 18+)
struct PawNovaMeshGradient: View {
    var animating: Bool = false
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: !animating)) { timeline in
            MeshGradient(
                width: 3,
                height: 3,
                points: meshPoints(phase: animating ? phase : 0),
                colors: [
                    // Top row
                    Color.pawBackground,
                    Color.pawPrimary.opacity(0.6),
                    Color.pawBackground,
                    // Middle row
                    Color.pawPrimary.opacity(0.4),
                    Color.pawSecondary.opacity(0.5),
                    Color.pawAccent.opacity(0.4),
                    // Bottom row
                    Color.pawBackground,
                    Color.pawSecondary.opacity(0.3),
                    Color.pawBackground
                ],
                smoothsColors: true
            )
            .onChange(of: timeline.date) {
                if animating {
                    withAnimation(.linear(duration: 0.033)) {
                        phase += 0.01
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func meshPoints(phase: CGFloat) -> [SIMD2<Float>] {
        let offset = Float(sin(phase * .pi * 2) * 0.05)
        return [
            // Top row
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + offset, 0.0),
            SIMD2(1.0, 0.0),
            // Middle row
            SIMD2(0.0, 0.5 - offset),
            SIMD2(0.5, 0.5),
            SIMD2(1.0, 0.5 + offset),
            // Bottom row
            SIMD2(0.0, 1.0),
            SIMD2(0.5 - offset, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }
}

/// Static mesh gradient for lighter weight usage
struct PawNovaStaticMeshGradient: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
            ],
            colors: [
                Color.pawBackground, Color.pawPrimary.opacity(0.3), Color.pawBackground,
                Color.pawPrimary.opacity(0.2), Color.pawSecondary.opacity(0.3), Color.pawAccent.opacity(0.2),
                Color.pawBackground, Color.pawSecondary.opacity(0.2), Color.pawBackground
            ],
            smoothsColors: true
        )
        .ignoresSafeArea()
    }
}

#Preview("Animated Mesh") {
    ZStack {
        PawNovaMeshGradient(animating: true)
        Text("PawNova")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
    }
}

#Preview("Static Mesh") {
    ZStack {
        PawNovaStaticMeshGradient()
        Text("PawNova")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
    }
}

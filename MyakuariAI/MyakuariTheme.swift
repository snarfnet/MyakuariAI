import SwiftUI

struct MyakuariTheme {
    static let ink = Color(red: 0.08, green: 0.04, blue: 0.12)
    static let plum = Color(red: 0.16, green: 0.07, blue: 0.24)
    static let wine = Color(red: 0.38, green: 0.08, blue: 0.25)
    static let rose = Color(red: 1.00, green: 0.34, blue: 0.58)
    static let coral = Color(red: 1.00, green: 0.48, blue: 0.50)
    static let lavender = Color(red: 0.60, green: 0.42, blue: 1.00)
    static let cream = Color(red: 1.00, green: 0.93, blue: 0.89)
    static let softText = Color.white.opacity(0.72)
    static let card = Color.white.opacity(0.105)
    static let stroke = Color.white.opacity(0.16)

    static var pageGradient: LinearGradient {
        LinearGradient(
            colors: [ink, plum, Color(red: 0.11, green: 0.05, blue: 0.17)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var romanceGradient: LinearGradient {
        LinearGradient(colors: [rose, coral, lavender], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct MyakuariBackground: View {
    var body: some View {
        ZStack {
            MyakuariTheme.pageGradient.ignoresSafeArea()
            Circle()
                .fill(MyakuariTheme.rose.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -160, y: -260)
            Circle()
                .fill(MyakuariTheme.lavender.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 180, y: 120)
            SparkleField()
                .opacity(0.65)
                .ignoresSafeArea()
        }
    }
}

struct SparkleField: View {
    private let points: [(CGFloat, CGFloat, CGFloat)] = [
        (0.12, 0.10, 3), (0.28, 0.18, 2), (0.72, 0.12, 4), (0.88, 0.24, 2),
        (0.18, 0.38, 2), (0.46, 0.31, 3), (0.80, 0.43, 3), (0.22, 0.68, 2),
        (0.58, 0.74, 3), (0.91, 0.82, 2)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: p.2, height: p.2)
                    .shadow(color: MyakuariTheme.rose, radius: 8)
                    .position(x: proxy.size.width * p.0, y: proxy.size.height * p.1)
            }
        }
    }
}

struct GlassPanel<Content: View>: View {
    let radius: CGFloat
    @ViewBuilder var content: Content

    init(radius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(MyakuariTheme.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(MyakuariTheme.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 12)
    }
}

struct GradientIcon: View {
    let systemName: String
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle()
                .fill(MyakuariTheme.romanceGradient)
                .shadow(color: MyakuariTheme.rose.opacity(0.45), radius: 14, x: 0, y: 6)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

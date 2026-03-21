import SwiftUI

struct ExperienceVisualStyle {
    let heroTop: Color
    let heroBottom: Color
    let accent: Color
    let surface: Color
    let border: Color
    let ink: Color
    let softTint: Color

    var heroGradient: LinearGradient {
        LinearGradient(colors: [heroTop, heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func make(for experience: Experience) -> ExperienceVisualStyle {
        switch experience.vibe {
        case .familyStyle:
            ExperienceVisualStyle(
                heroTop: Color(red: 0.96, green: 0.58, blue: 0.24),
                heroBottom: Color(red: 0.77, green: 0.25, blue: 0.19),
                accent: Color(red: 0.89, green: 0.36, blue: 0.17),
                surface: Color(red: 1.00, green: 0.96, blue: 0.90),
                border: Color(red: 0.89, green: 0.74, blue: 0.57),
                ink: Color(red: 0.18, green: 0.12, blue: 0.10),
                softTint: Color(red: 1.00, green: 0.84, blue: 0.63)
            )
        case .storytelling:
            ExperienceVisualStyle(
                heroTop: Color(red: 0.84, green: 0.37, blue: 0.34),
                heroBottom: Color(red: 0.42, green: 0.15, blue: 0.20),
                accent: Color(red: 0.73, green: 0.26, blue: 0.24),
                surface: Color(red: 0.99, green: 0.94, blue: 0.92),
                border: Color(red: 0.82, green: 0.65, blue: 0.63),
                ink: Color(red: 0.17, green: 0.10, blue: 0.12),
                softTint: Color(red: 0.95, green: 0.79, blue: 0.76)
            )
        case .chefTable:
            ExperienceVisualStyle(
                heroTop: Color(red: 0.13, green: 0.55, blue: 0.55),
                heroBottom: Color(red: 0.12, green: 0.28, blue: 0.40),
                accent: Color(red: 0.16, green: 0.47, blue: 0.55),
                surface: Color(red: 0.92, green: 0.97, blue: 0.97),
                border: Color(red: 0.63, green: 0.81, blue: 0.82),
                ink: Color(red: 0.08, green: 0.16, blue: 0.18),
                softTint: Color(red: 0.69, green: 0.88, blue: 0.90)
            )
        case .festive:
            ExperienceVisualStyle(
                heroTop: Color(red: 0.97, green: 0.38, blue: 0.39),
                heroBottom: Color(red: 0.84, green: 0.16, blue: 0.33),
                accent: Color(red: 0.92, green: 0.33, blue: 0.22),
                surface: Color(red: 0.99, green: 0.93, blue: 0.91),
                border: Color(red: 0.89, green: 0.63, blue: 0.57),
                ink: Color(red: 0.17, green: 0.09, blue: 0.12),
                softTint: Color(red: 1.00, green: 0.78, blue: 0.62)
            )
        }
    }
}

struct FestiveMarketplaceBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.92)
            Circle()
                .fill(Color(red: 1.00, green: 0.73, blue: 0.55).opacity(0.30))
                .frame(width: 320, height: 320)
                .blur(radius: 16)
                .offset(x: -140, y: -260)
            Circle()
                .fill(Color(red: 0.94, green: 0.43, blue: 0.35).opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 28)
                .offset(x: 160, y: 60)
            Circle()
                .fill(Color(red: 0.20, green: 0.58, blue: 0.59).opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 24)
                .offset(x: -120, y: 340)
        }
        .ignoresSafeArea()
    }
}

struct FestiveTag: View {
    let text: String
    let fill: Color
    let foreground: Color

    init(text: String, fill: Color, foreground: Color = .white) {
        self.text = text
        self.fill = fill
        self.foreground = foreground
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(fill, in: Capsule())
            .foregroundStyle(foreground)
    }
}

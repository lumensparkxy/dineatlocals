import SwiftUI

enum SupperClubPalette {
    static let background = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let backgroundTop = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let paperWarm = Color(red: 0.95, green: 0.91, blue: 0.87)
    static let border = Color(red: 0.89, green: 0.85, blue: 0.79)
    static let ink = Color(red: 0.16, green: 0.14, blue: 0.12)
    static let muted = Color(red: 0.43, green: 0.38, blue: 0.35)
    static let oxblood = Color(red: 0.29, green: 0.08, blue: 0.14)
    static let aubergine = Color(red: 0.21, green: 0.06, blue: 0.11)
    static let sage = Color(red: 0.43, green: 0.46, blue: 0.33)
    static let blush = Color(red: 0.95, green: 0.91, blue: 0.87)
    static let clay = Color(red: 0.79, green: 0.35, blue: 0.23)
    static let amber = Color(red: 0.82, green: 0.55, blue: 0.26)
    static let warmShadow = Color(red: 0.22, green: 0.12, blue: 0.10)
}

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
                heroTop: SupperClubPalette.clay,
                heroBottom: SupperClubPalette.oxblood,
                accent: SupperClubPalette.clay,
                surface: SupperClubPalette.paper,
                border: SupperClubPalette.border,
                ink: SupperClubPalette.ink,
                softTint: SupperClubPalette.blush
            )
        case .storytelling:
            ExperienceVisualStyle(
                heroTop: SupperClubPalette.oxblood,
                heroBottom: SupperClubPalette.aubergine,
                accent: SupperClubPalette.oxblood,
                surface: SupperClubPalette.paper,
                border: SupperClubPalette.border,
                ink: SupperClubPalette.ink,
                softTint: SupperClubPalette.blush
            )
        case .chefTable:
            ExperienceVisualStyle(
                heroTop: SupperClubPalette.sage,
                heroBottom: SupperClubPalette.aubergine,
                accent: SupperClubPalette.sage,
                surface: SupperClubPalette.paper,
                border: SupperClubPalette.border,
                ink: SupperClubPalette.ink,
                softTint: Color(red: 0.89, green: 0.92, blue: 0.84)
            )
        case .festive:
            ExperienceVisualStyle(
                heroTop: SupperClubPalette.clay,
                heroBottom: SupperClubPalette.aubergine,
                accent: SupperClubPalette.clay,
                surface: SupperClubPalette.paper,
                border: SupperClubPalette.border,
                ink: SupperClubPalette.ink,
                softTint: Color(red: 0.96, green: 0.88, blue: 0.80)
            )
        }
    }
}

struct FestiveMarketplaceBackground: View {
    var body: some View {
        LinearGradient(
            colors: [SupperClubPalette.backgroundTop, SupperClubPalette.background],
            startPoint: .top,
            endPoint: .bottom
        )
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
            .background(fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(foreground)
    }
}

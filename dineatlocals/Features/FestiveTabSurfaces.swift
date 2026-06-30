import SwiftUI

struct FestiveTabTheme {
    let heroTop: Color
    let heroBottom: Color
    let accent: Color
    let secondaryAccent: Color
    let surface: Color
    let border: Color
    let ink: Color
    let mutedInk: Color
    let softTint: Color

    var heroGradient: LinearGradient {
        LinearGradient(colors: [heroTop, heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension FestiveTabTheme {
    static let requests = FestiveTabTheme(
        heroTop: SupperClubPalette.oxblood,
        heroBottom: SupperClubPalette.aubergine,
        accent: SupperClubPalette.oxblood,
        secondaryAccent: SupperClubPalette.sage,
        surface: SupperClubPalette.paper,
        border: SupperClubPalette.border,
        ink: SupperClubPalette.ink,
        mutedInk: SupperClubPalette.muted,
        softTint: SupperClubPalette.blush
    )

    static let host = FestiveTabTheme(
        heroTop: SupperClubPalette.sage,
        heroBottom: SupperClubPalette.aubergine,
        accent: SupperClubPalette.sage,
        secondaryAccent: SupperClubPalette.oxblood,
        surface: SupperClubPalette.paper,
        border: SupperClubPalette.border,
        ink: SupperClubPalette.ink,
        mutedInk: SupperClubPalette.muted,
        softTint: Color(red: 0.89, green: 0.92, blue: 0.84)
    )

    static let profile = FestiveTabTheme(
        heroTop: SupperClubPalette.oxblood,
        heroBottom: SupperClubPalette.aubergine,
        accent: SupperClubPalette.oxblood,
        secondaryAccent: SupperClubPalette.sage,
        surface: SupperClubPalette.paper,
        border: SupperClubPalette.border,
        ink: SupperClubPalette.ink,
        mutedInk: SupperClubPalette.muted,
        softTint: SupperClubPalette.blush
    )
}

struct FestiveHeroCard<Content: View>: View {
    let theme: FestiveTabTheme
    let eyebrow: String?
    let title: String
    let subtitle: String
    let content: Content

    init(
        theme: FestiveTabTheme,
        eyebrow: String? = nil,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.footnote.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(theme.accent)
                }

                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.ink)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .padding(20)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.05), radius: 12, y: 6)
    }
}

extension FestiveHeroCard where Content == EmptyView {
    init(theme: FestiveTabTheme, eyebrow: String? = nil, title: String, subtitle: String) {
        self.init(theme: theme, eyebrow: eyebrow, title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct FestiveSectionCard<Content: View>: View {
    let theme: FestiveTabTheme
    let fill: Color?
    let content: Content

    init(theme: FestiveTabTheme, fill: Color? = nil, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(18)
        .background((fill ?? theme.surface), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.04), radius: 10, y: 5)
    }
}

struct FestiveSectionHeading: View {
    let theme: FestiveTabTheme
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.footnote.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(theme.accent.opacity(0.86))

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.ink)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.mutedInk.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FestiveMetricChip: View {
    let theme: FestiveTabTheme
    let value: String
    let label: String
    let highlight: Color?

    init(theme: FestiveTabTheme, value: String, label: String, highlight: Color? = nil) {
        self.theme = theme
        self.value = value
        self.label = label
        self.highlight = highlight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(theme.ink)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background((highlight ?? SupperClubPalette.paperWarm).opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.border.opacity(0.75), lineWidth: 1)
        )
    }
}

struct FestiveChoicePill: View {
    let title: String
    let isSelected: Bool
    let theme: FestiveTabTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : theme.ink)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(isSelected ? theme.secondaryAccent : theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.clear : theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FestiveEmptyStateCard: View {
    let theme: FestiveTabTheme
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        FestiveSectionCard(theme: theme, fill: theme.surface) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.accent)

                Text(title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(theme.ink)

                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.mutedInk.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FestiveActionButtonStyle: ButtonStyle {
    let tint: Color
    let foreground: Color

    init(tint: Color, foreground: Color = .white) {
        self.tint = tint
        self.foreground = foreground
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(tint.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FestiveInputSurfaceModifier: ViewModifier {
    let theme: FestiveTabTheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(SupperClubPalette.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            )
            .foregroundStyle(theme.ink)
    }
}

extension View {
    func festiveInputSurface(theme: FestiveTabTheme) -> some View {
        modifier(FestiveInputSurfaceModifier(theme: theme))
    }
}

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
        heroTop: Color(red: 0.97, green: 0.54, blue: 0.42),
        heroBottom: Color(red: 0.78, green: 0.27, blue: 0.26),
        accent: Color(red: 0.89, green: 0.35, blue: 0.22),
        secondaryAccent: Color(red: 0.18, green: 0.48, blue: 0.54),
        surface: Color(red: 0.99, green: 0.94, blue: 0.91),
        border: Color(red: 0.90, green: 0.72, blue: 0.60),
        ink: Color(red: 0.18, green: 0.10, blue: 0.11),
        mutedInk: Color(red: 0.36, green: 0.22, blue: 0.18),
        softTint: Color(red: 1.00, green: 0.84, blue: 0.72)
    )

    static let host = FestiveTabTheme(
        heroTop: Color(red: 0.27, green: 0.47, blue: 0.54),
        heroBottom: Color(red: 0.17, green: 0.28, blue: 0.36),
        accent: Color(red: 0.15, green: 0.45, blue: 0.53),
        secondaryAccent: Color(red: 0.94, green: 0.58, blue: 0.32),
        surface: Color(red: 0.93, green: 0.97, blue: 0.97),
        border: Color(red: 0.67, green: 0.81, blue: 0.83),
        ink: Color(red: 0.08, green: 0.16, blue: 0.19),
        mutedInk: Color(red: 0.20, green: 0.31, blue: 0.35),
        softTint: Color(red: 0.73, green: 0.89, blue: 0.90)
    )

    static let profile = FestiveTabTheme(
        heroTop: Color(red: 0.92, green: 0.42, blue: 0.44),
        heroBottom: Color(red: 0.62, green: 0.20, blue: 0.33),
        accent: Color(red: 0.84, green: 0.32, blue: 0.29),
        secondaryAccent: Color(red: 0.26, green: 0.58, blue: 0.57),
        surface: Color(red: 0.99, green: 0.94, blue: 0.93),
        border: Color(red: 0.87, green: 0.69, blue: 0.66),
        ink: Color(red: 0.18, green: 0.10, blue: 0.12),
        mutedInk: Color(red: 0.39, green: 0.21, blue: 0.22),
        softTint: Color(red: 0.96, green: 0.79, blue: 0.76)
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
                        .foregroundStyle(Color.white.opacity(0.74))
                }

                Text(title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .padding(22)
        .background(theme.heroGradient, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: theme.accent.opacity(0.15), radius: 24, y: 14)
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
        .padding(20)
        .background((fill ?? theme.surface), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.border.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: theme.accent.opacity(0.08), radius: 16, y: 10)
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
                .font(.title3.weight(.black))
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
        .background((highlight ?? Color.white).opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .padding(.vertical, 11)
                .background(isSelected ? theme.secondaryAccent : Color.white.opacity(0.78), in: Capsule())
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
        FestiveSectionCard(theme: theme, fill: Color.white.opacity(0.84)) {
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
            .background(tint.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
    }
}

private struct FestiveInputSurfaceModifier: ViewModifier {
    let theme: FestiveTabTheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.border.opacity(0.64), lineWidth: 1)
            )
            .foregroundStyle(theme.ink)
    }
}

extension View {
    func festiveInputSurface(theme: FestiveTabTheme) -> some View {
        modifier(FestiveInputSurfaceModifier(theme: theme))
    }
}

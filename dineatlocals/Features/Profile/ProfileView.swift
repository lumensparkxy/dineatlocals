import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @Query(sort: \CachedExperienceRecord.updatedAt, order: .reverse) private var cachedExperiences: [CachedExperienceRecord]

    @State private var bio = ""
    @State private var dietaryPreferences = ""
    @State private var spokenLanguages = ""

    private let theme = FestiveTabTheme.profile

    var body: some View {
        ZStack {
            FestiveMarketplaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    passportHero
                    guestPreferencesCard
                    cacheCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: appModel.guestProfile) {
            if let guestProfile = appModel.guestProfile {
                bio = guestProfile.bio
                dietaryPreferences = guestProfile.dietaryPreferences.joined(separator: ", ")
                spokenLanguages = guestProfile.spokenLanguages.joined(separator: ", ")
            }
        }
    }

    private var passportHero: some View {
        FestiveHeroCard(
            theme: theme,
            eyebrow: "Member Passport",
            title: "Profile",
            subtitle: "Your tastes, languages, and trust markers shape better matches around the table."
        ) {
            if let currentUser = appModel.currentUser {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(monogram(for: currentUser.fullName))
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(theme.accent, in: Circle())

                        VStack(alignment: .leading, spacing: 5) {
                            Text(currentUser.fullName)
                                .font(.title3.weight(.black))
                                .foregroundStyle(theme.ink)

                            Text(currentUser.email)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.mutedInk)
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(currentUser.roles, id: \.rawValue) { role in
                            FestiveTag(text: role.rawValue.capitalized, fill: theme.softTint, foreground: theme.ink)
                        }
                    }

                    HStack(spacing: 10) {
                        passportBadge(title: currentUser.city, icon: "mappin.and.ellipse")
                        passportBadge(title: currentUser.verificationState.title, icon: "checkmark.shield")
                    }
                }
            }
        }
    }

    private var guestPreferencesCard: some View {
        FestiveSectionCard(theme: theme) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Guest Profile",
                title: "Curate how you show up",
                subtitle: "A little context helps hosts understand your taste, dietary needs, and conversation style."
            )

            if !bio.isEmpty {
                Text(bio)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .background(SupperClubPalette.paperWarm.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !parsedDietaryPreferences.isEmpty {
                PreferenceTagSection(
                    title: "Dietary preferences",
                    values: parsedDietaryPreferences,
                    fill: theme.softTint,
                    foreground: theme.ink
                )
            }

            if !parsedLanguages.isEmpty {
                PreferenceTagSection(
                    title: "Languages",
                    values: parsedLanguages,
                    fill: theme.softTint.opacity(0.88),
                    foreground: theme.ink
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                ProfileField(title: "Bio", text: $bio, axis: .vertical)
                ProfileField(title: "Dietary preferences", prompt: "Comma separated", text: $dietaryPreferences)
                ProfileField(title: "Languages", prompt: "Comma separated", text: $spokenLanguages)
            }

            Button("Save guest profile") {
                Task {
                    await appModel.saveGuestProfile(
                        bio: bio,
                        dietaryPreferences: parsedDietaryPreferences,
                        spokenLanguages: parsedLanguages
                    )
                }
            }
            .buttonStyle(FestiveActionButtonStyle(tint: theme.accent))
        }
    }

    private var cacheCard: some View {
        FestiveSectionCard(theme: theme, fill: SupperClubPalette.paper) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Offline Cache",
                title: "Discovery saved locally",
                subtitle: "Supporting account info for when you come back without a network connection."
            )

            HStack(spacing: 10) {
                FestiveMetricChip(theme: theme, value: "\(cachedExperiences.count)", label: "cached items")

                if let newestCache = cachedExperiences.first {
                    FestiveMetricChip(
                        theme: theme,
                        value: newestCache.updatedAt.formatted(.dateTime.day().month()),
                        label: newestCache.updatedAt.formatted(.dateTime.hour().minute()),
                        highlight: theme.softTint
                    )
                }
            }
        }
    }

    private var parsedDietaryPreferences: [String] {
        parseCSVList(dietaryPreferences)
    }

    private var parsedLanguages: [String] {
        parseCSVList(spokenLanguages)
    }

    private func passportBadge(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(theme.accent)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.softTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func monogram(for name: String) -> String {
        String(name.prefix(1))
    }
}

private struct ProfileField: View {
    let title: String
    var prompt: String?
    @Binding var text: String
    var axis: Axis = .horizontal

    private let theme = FestiveTabTheme.profile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(theme.accent.opacity(0.84))

                if let prompt {
                    Text(prompt)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.mutedInk.opacity(0.72))
                }
            }

            TextField(title, text: $text, axis: axis)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
                .textFieldStyle(.plain)
                .festiveInputSurface(theme: theme)
        }
    }
}

private struct PreferenceTagSection: View {
    let title: String
    let values: [String]
    let fill: Color
    let foreground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(foreground.opacity(0.72))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(values, id: \.self) { value in
                    FestiveTag(text: value, fill: fill, foreground: foreground)
                }
            }
        }
    }
}

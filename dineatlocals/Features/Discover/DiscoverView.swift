import SwiftUI

struct DiscoverView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        ZStack {
            FestiveMarketplaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    discoverHeader
                    experienceCards
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: appModel.discoverFilter) {
            guard appModel.hasLoaded else { return }
            await appModel.reloadDiscover()
        }
    }

    private var discoverHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Discover")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.17, green: 0.09, blue: 0.12))
                Text("Shared tables, cultural stories, and home-cooked meals that feel social before they feel transactional.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(red: 0.39, green: 0.23, blue: 0.19).opacity(0.85))
            }

            DiscoverSearchField(text: Binding(
                get: { appModel.discoverFilter.searchText },
                set: { appModel.discoverFilter.searchText = $0 }
            ))

            HStack(spacing: 10) {
                FestiveStatPill(title: "\(appModel.availableCities.count)", subtitle: "cities")
                FestiveStatPill(title: "\(appModel.experiences.count)", subtitle: "tables now")
                FestiveStatPill(title: "Hosts", subtitle: "verified")
            }

            filterSection(title: "Cities") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(
                            title: "All Cities",
                            isSelected: appModel.discoverFilter.city == nil,
                            fillColor: Color(red: 0.91, green: 0.37, blue: 0.25),
                            inactiveColor: Color.white.opacity(0.68)
                        ) {
                            appModel.discoverFilter.city = nil
                        }
                        .accessibilityIdentifier("discover.city.all")

                        ForEach(appModel.availableCities, id: \.self) { city in
                            FilterChip(
                                title: city,
                                isSelected: appModel.discoverFilter.city == city,
                                fillColor: Color(red: 0.91, green: 0.37, blue: 0.25),
                                inactiveColor: Color.white.opacity(0.68)
                            ) {
                                appModel.discoverFilter.city = city
                            }
                            .accessibilityIdentifier("discover.city.\(city)")
                        }
                    }
                }
            }

            filterSection(title: "Meals") {
                HStack(spacing: 10) {
                    FilterChip(
                        title: "All Meals",
                        isSelected: appModel.discoverFilter.mealType == nil,
                        fillColor: Color(red: 0.16, green: 0.47, blue: 0.55),
                        inactiveColor: Color.white.opacity(0.68)
                    ) {
                        appModel.discoverFilter.mealType = nil
                    }

                    ForEach(ExperienceMealType.allCases) { mealType in
                        FilterChip(
                            title: mealType.title,
                            isSelected: appModel.discoverFilter.mealType == mealType,
                            fillColor: Color(red: 0.16, green: 0.47, blue: 0.55),
                            inactiveColor: Color.white.opacity(0.68)
                        ) {
                            appModel.discoverFilter.mealType = mealType
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.86, blue: 0.72),
                    Color(red: 0.98, green: 0.68, blue: 0.58),
                    Color(red: 0.93, green: 0.45, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.35, green: 0.12, blue: 0.10).opacity(0.10), radius: 22, y: 12)
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.28, green: 0.13, blue: 0.11).opacity(0.75))
            content()
        }
    }

    private var experienceCards: some View {
        LazyVStack(spacing: 18) {
            if appModel.experiences.isEmpty {
                ContentUnavailableView(
                    "No Meals Match Yet",
                    systemImage: "fork.knife.circle",
                    description: Text("Try widening the city or meal filter.")
                )
                .padding(.top, 40)
            } else {
                ForEach(appModel.experiences) { experience in
                    NavigationLink {
                        ExperienceDetailView(experienceID: experience.id)
                    } label: {
                        ExperienceCard(experience: experience)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct DiscoverSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(red: 0.45, green: 0.25, blue: 0.22))
            TextField("Search cuisine, city, or host", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct FestiveStatPill: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline.weight(.bold))
            Text(subtitle)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color(red: 0.18, green: 0.10, blue: 0.12))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ExperienceCard: View {
    let experience: Experience

    private var style: ExperienceVisualStyle {
        ExperienceVisualStyle.make(for: experience)
    }

    private var leadPhotoAssetName: String {
        experience.photoAssetNames.first
        ?? ExperienceMediaCatalog.photoAssetNames(
            cuisineOrigin: experience.cuisineOrigin,
            vibe: experience.vibe,
            mealType: experience.mealType
        ).first
        ?? "gallery-hearth-01"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image(leadPhotoAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()

                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.10), Color.black.opacity(0.62)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    style.heroGradient.opacity(0.50)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                FestiveTag(text: experience.mealType.title, fill: Color.white.opacity(0.22))
                                FestiveTag(text: experience.vibe.title, fill: Color.black.opacity(0.22))
                            }

                            Text(experience.title)
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)

                            Text(experience.cuisineOrigin)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.white.opacity(0.92))
                        }

                        Spacer(minLength: 12)

                        hostMonogram
                    }

                    Text(experience.description)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.90))
                        .lineLimit(2)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experience.hostName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(style.ink)
                        Text("Hosted in \(experience.neighborhood), \(experience.city)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(style.ink.opacity(0.72))
                    }

                    Spacer()

                    if let nextStartAt = experience.nextStartAt {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Next table")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(style.accent)
                            Text(nextStartAt, format: .dateTime.weekday(.abbreviated).day().month().hour().minute())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(style.ink)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Rectangle()
                    .fill(style.border.opacity(0.45))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 10) {
                    CardFactRow(icon: "mappin.and.ellipse", text: "\(experience.neighborhood), \(experience.city)", tint: style.accent)
                    CardFactRow(icon: "person.2.wave.2.fill", text: "\(experience.maxSeats) seats around one table", tint: style.accent)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        InfoPill(text: experience.spokenLanguages.joined(separator: " / "), fill: style.softTint, foreground: style.ink)
                        InfoPill(text: experience.dietarySupport.first ?? "Flexible menu", fill: style.softTint.opacity(0.82), foreground: style.ink)
                    }
                }
            }
            .padding(20)
            .background(style.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(style.border.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: style.accent.opacity(0.12), radius: 18, y: 10)
    }

    private var hostMonogram: some View {
        Text(String(experience.hostName.prefix(1)))
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(Color.white.opacity(0.16), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
    }
}

private struct CardFactRow: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let fillColor: Color
    let inactiveColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? fillColor : inactiveColor, in: Capsule())
                .foregroundStyle(isSelected ? .white : Color(red: 0.24, green: 0.14, blue: 0.12))
        }
        .buttonStyle(.plain)
    }
}

private struct InfoPill: View {
    let text: String
    let fill: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(fill, in: Capsule())
            .foregroundStyle(foreground)
    }
}

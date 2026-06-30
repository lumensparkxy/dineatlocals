import SwiftUI

struct DiscoverView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        ZStack {
            FestiveMarketplaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    discoverHeader
                    experienceCards
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 34)
                .festiveReadableColumn(maxWidth: 1080)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: appModel.discoverFilter) {
            guard appModel.hasLoaded else { return }
            await appModel.reloadDiscover()
        }
    }

    private var discoverHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("DineAtLocals")
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(SupperClubPalette.ink)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(SupperClubPalette.ink)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Discover")
                    .font(.system(size: 44, weight: .semibold, design: .serif))
                    .foregroundStyle(SupperClubPalette.ink)
                Text("Hosted meals, cultural stories, and small tables that feel personal before they feel transactional.")
                    .font(.subheadline)
                    .foregroundStyle(SupperClubPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DiscoverSearchField(text: Binding(
                get: { appModel.discoverFilter.searchText },
                set: { appModel.discoverFilter.searchText = $0 }
            ))

            filterSection(title: "Cities") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(
                            title: "All",
                            isSelected: appModel.discoverFilter.city == nil,
                            fillColor: SupperClubPalette.oxblood,
                            inactiveColor: SupperClubPalette.paper
                        ) {
                            appModel.discoverFilter.city = nil
                        }
                        .accessibilityIdentifier("discover.city.all")

                        ForEach(appModel.availableCities, id: \.self) { city in
                            FilterChip(
                                title: city,
                                isSelected: appModel.discoverFilter.city == city,
                                fillColor: SupperClubPalette.oxblood,
                                inactiveColor: SupperClubPalette.paper
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
                        title: "All meals",
                        isSelected: appModel.discoverFilter.mealType == nil,
                        fillColor: SupperClubPalette.sage,
                        inactiveColor: SupperClubPalette.paper
                    ) {
                        appModel.discoverFilter.mealType = nil
                    }

                    ForEach(ExperienceMealType.allCases) { mealType in
                        FilterChip(
                            title: mealType.title,
                            isSelected: appModel.discoverFilter.mealType == mealType,
                            fillColor: SupperClubPalette.sage,
                            inactiveColor: SupperClubPalette.paper
                        ) {
                            appModel.discoverFilter.mealType = mealType
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                FestiveStatPill(title: "\(appModel.availableCities.count)", subtitle: "cities")
                FestiveStatPill(title: "\(appModel.experiences.count)", subtitle: "tables now")
                FestiveStatPill(title: "Hosts", subtitle: "verified")
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(SupperClubPalette.muted)
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
                .foregroundStyle(SupperClubPalette.muted)
            TextField("Search cuisine, city, or host", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SupperClubPalette.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(SupperClubPalette.border, lineWidth: 1)
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
        .background(SupperClubPalette.paperWarm.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(SupperClubPalette.border.opacity(0.8), lineWidth: 1)
        )
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

    private var nextSlot: ExperienceSlot? {
        experience.bookableSlots.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(leadPhotoAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 224)
                    .clipped()

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Verified host")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(SupperClubPalette.sage.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(14)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            FestiveTag(text: experience.mealType.title, fill: style.softTint, foreground: style.ink)
                            FestiveTag(text: experience.vibe.title, fill: SupperClubPalette.paperWarm, foreground: style.ink)
                        }

                        Text(experience.title)
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundStyle(style.ink)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "heart")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(style.accent)
                }

                Text("Hosted by \(experience.hostName) in \(experience.neighborhood), \(experience.city)")
                    .font(.subheadline)
                    .foregroundStyle(style.mutedText)

                Text(experience.description)
                    .font(.subheadline)
                    .foregroundStyle(style.ink.opacity(0.78))
                    .lineLimit(2)

                Divider()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 14) {
                    if let nextSlot {
                        CardFactRow(icon: "calendar", title: "Next table", text: nextSlot.startAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()), tint: style.accent)
                        CardFactRow(icon: "person.2", title: "Seats", text: "\(nextSlot.remainingSeats) left of \(nextSlot.seatCapacity)", tint: style.accent)
                    } else {
                        CardFactRow(icon: "calendar.badge.exclamationmark", title: "Next table", text: "No open dates", tint: style.accent)
                        CardFactRow(icon: "person.2", title: "Seats", text: "\(experience.maxSeats) max", tint: style.accent)
                    }
                    CardFactRow(icon: "globe", title: "Languages", text: experience.spokenLanguages.joined(separator: " / "), tint: style.accent)
                    CardFactRow(icon: "lock", title: "Address", text: "After acceptance", tint: style.accent)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        InfoPill(text: experience.dietarySupport.first ?? "Flexible menu", fill: style.softTint, foreground: style.ink)
                        InfoPill(text: experience.cuisineOrigin, fill: SupperClubPalette.paperWarm, foreground: style.ink)
                    }
                }
            }
            .padding(20)
            .background(style.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style.border, lineWidth: 1)
        )
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.06), radius: 14, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(experience.title)
        .accessibilityLabel(experience.title)
        .accessibilityValue(
            "Verified host, \(experience.mealType.title), \(experience.vibe.title), hosted by \(experience.hostName) in \(experience.neighborhood), \(experience.city)"
        )
        .accessibilityHint("Opens experience details")
    }
}

private struct CardFactRow: View {
    let icon: String
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.subheadline.weight(.semibold))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(SupperClubPalette.muted)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SupperClubPalette.ink)
                    .lineLimit(2)
            }
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
                .padding(.vertical, 9)
                .background(isSelected ? fillColor : inactiveColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.clear : SupperClubPalette.border, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .white : SupperClubPalette.ink)
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
            .background(fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(foreground)
    }
}

private extension ExperienceVisualStyle {
    var mutedText: Color {
        ink.opacity(0.68)
    }
}

import SwiftUI

struct HostingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var hostApplication = HostApplicationDraft()
    @State private var isCreateExperiencePresented = false

    private let theme = FestiveTabTheme.host
    private let statColumns = [GridItem(.adaptive(minimum: 112), spacing: 10)]

    var body: some View {
        ZStack {
            FestiveMarketplaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch appModel.hostProfile?.approvalStatus {
                    case .approved, .paused:
                        approvedHostDashboard
                    case .pendingReview:
                        pendingHostState
                    case .notApplied:
                        hostApplicationFlow
                    case .none:
                        hostApplicationFlow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isCreateExperiencePresented) {
            CreateExperienceSheet(isPresented: $isCreateExperiencePresented)
                .presentationDetents([.large])
        }
        .task(id: appModel.hostProfile) {
            if let hostProfile = appModel.hostProfile {
                hostApplication = HostApplicationDraft(
                    homeCity: hostProfile.homeCity,
                    neighborhood: hostProfile.neighborhood,
                    spokenLanguages: hostProfile.spokenLanguages,
                    cultureStory: hostProfile.cultureStory,
                    houseRules: hostProfile.houseRules,
                    safetyNotes: hostProfile.safetyNotes
                )
            } else if let currentUser = appModel.currentUser {
                hostApplication.homeCity = currentUser.city
            }
        }
    }

    private var approvedHostDashboard: some View {
        VStack(alignment: .leading, spacing: 24) {
            hostStudioHero

            if let hostProfile = appModel.hostProfile {
                HostSummaryCard(hostProfile: hostProfile)
            }

            listingsSection

            if !appModel.moderationRecords.isEmpty {
                reviewLogSection
            }
        }
    }

    private var hostStudioHero: some View {
        FestiveHeroCard(
            theme: theme,
            eyebrow: "Creator Studio",
            title: "Host Studio",
            subtitle: "Shape a table that feels generous, intentional, and easy for guests to trust."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: statColumns, spacing: 10) {
                    FestiveMetricChip(
                        theme: theme,
                        value: "\(appModel.hostExperiences.filter { $0.publishState == .published }.count)",
                        label: "live tables"
                    )
                    FestiveMetricChip(
                        theme: theme,
                        value: "\(appModel.hostRequests.filter { $0.status == .pending }.count)",
                        label: "pending requests",
                        highlight: theme.softTint
                    )
                    FestiveMetricChip(
                        theme: theme,
                        value: appModel.hostProfile?.approvalStatus.title ?? "Not set",
                        label: "trust state",
                        highlight: theme.softTint.opacity(0.82)
                    )
                }

                Button {
                    isCreateExperiencePresented = true
                } label: {
                    Label("Create Experience", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FestiveActionButtonStyle(tint: theme.secondaryAccent, foreground: theme.ink))
                .accessibilityIdentifier("host.createExperience")
            }
        }
    }

    private var listingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Your Tables",
                title: "Published experiences",
                subtitle: "Pause, reopen, and block busy dates without rebuilding the listing."
            )

            if appModel.hostExperiences.isEmpty {
                FestiveEmptyStateCard(
                    theme: theme,
                    symbolName: "house.lodge",
                    title: "No Hosted Meals Yet",
                    message: "Create your first lunch or dinner listing to start welcoming guests into your home."
                )
            } else {
                ForEach(appModel.hostExperiences) { experience in
                    HostExperienceCard(experience: experience)
                }
            }
        }
    }

    private var reviewLogSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Trust",
                title: "Review log",
                subtitle: "A simple history of approval decisions while the marketplace still runs with manual moderation."
            )

            ForEach(appModel.moderationRecords) { record in
                FestiveSectionCard(theme: theme, fill: Color.white.opacity(0.78)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 10) {
                            Circle()
                                .fill(theme.secondaryAccent)
                                .frame(width: 10, height: 10)

                            Text(record.status.title)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(theme.ink)

                            Spacer()

                            Text(record.reviewedAt, format: .dateTime.day().month().year())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.mutedInk)
                        }

                        Text(record.note)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var pendingHostState: some View {
        VStack(alignment: .leading, spacing: 24) {
            FestiveHeroCard(
                theme: theme,
                eyebrow: "Application Journey",
                title: "Under Review",
                subtitle: "Your host profile is in the manual trust queue. Publishing unlocks as soon as the review is complete."
            ) {
                LazyVGrid(columns: statColumns, spacing: 10) {
                    FestiveMetricChip(theme: theme, value: "Profile", label: "submitted")
                    FestiveMetricChip(theme: theme, value: "Manual", label: "review", highlight: theme.softTint)
                    FestiveMetricChip(theme: theme, value: "Locked", label: "publishing", highlight: theme.softTint.opacity(0.82))
                }
            }

            if let hostProfile = appModel.hostProfile {
                HostSummaryCard(hostProfile: hostProfile)
            }

            if let latestReview = appModel.moderationRecords.first {
                FestiveSectionCard(theme: theme, fill: Color.white.opacity(0.78)) {
                    FestiveSectionHeading(
                        theme: theme,
                        eyebrow: "Latest Note",
                        title: "What the review team recorded",
                        subtitle: nil
                    )

                    Text(latestReview.note)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var hostApplicationFlow: some View {
        VStack(alignment: .leading, spacing: 24) {
            FestiveHeroCard(
                theme: theme,
                eyebrow: "Become A Host",
                title: "Open Your Table",
                subtitle: "Start with your story, neighborhood, and house rhythm. Manual approval keeps the first version high-trust."
            ) {
                LazyVGrid(columns: statColumns, spacing: 10) {
                    FestiveMetricChip(theme: theme, value: "Story", label: "culture-led")
                    FestiveMetricChip(theme: theme, value: "Home", label: "small group", highlight: theme.softTint)
                    FestiveMetricChip(theme: theme, value: "Review", label: "manual", highlight: theme.softTint.opacity(0.82))
                }
            }

            hostApplicationForm
        }
    }

    private var hostApplicationForm: some View {
        FestiveSectionCard(theme: theme) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Application",
                title: "Tell guests what kind of host you are",
                subtitle: "These details shape trust now and become the base of your host identity later."
            )

            VStack(alignment: .leading, spacing: 14) {
                StudioField(title: "Home city", text: $hostApplication.homeCity)
                StudioField(title: "Neighborhood", text: $hostApplication.neighborhood)
                StudioField(
                    title: "Languages",
                    prompt: "Comma separated",
                    text: Binding(
                        get: { hostApplication.spokenLanguages.joined(separator: ", ") },
                        set: { hostApplication.spokenLanguages = parseCSVList($0) }
                    )
                )
                StudioField(title: "Culture story", text: $hostApplication.cultureStory, axis: .vertical)
                StudioField(title: "House rules", text: $hostApplication.houseRules, axis: .vertical)
                StudioField(title: "Safety notes", text: $hostApplication.safetyNotes, axis: .vertical)
            }

            Button {
                Task {
                    await appModel.submitHostApplication(draft: hostApplication)
                }
            } label: {
                Label("Submit Host Application", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FestiveActionButtonStyle(tint: theme.accent))
        }
    }
}

private struct HostSummaryCard: View {
    @Environment(AppModel.self) private var appModel

    let hostProfile: HostProfile

    private let theme = FestiveTabTheme.host

    var body: some View {
        FestiveSectionCard(theme: theme) {
            HStack(alignment: .top, spacing: 14) {
                Text(monogram)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(theme.accent, in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(appModel.currentUser?.fullName ?? "Host")
                        .font(.title3.weight(.black))
                        .foregroundStyle(theme.ink)

                    Text("\(hostProfile.neighborhood), \(hostProfile.homeCity)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.mutedInk)
                }

                Spacer()

                Text(hostProfile.approvalStatus.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.softTint, in: Capsule())
            }

            if !hostProfile.spokenLanguages.isEmpty {
                FlowTagSection(title: "Languages", values: hostProfile.spokenLanguages, fill: theme.softTint, foreground: theme.ink)
            }

            HostDetailBlock(title: "Culture story", value: hostProfile.cultureStory)
            HostDetailBlock(title: "House rules", value: hostProfile.houseRules)
            HostDetailBlock(title: "Safety notes", value: hostProfile.safetyNotes)
        }
    }

    private var monogram: String {
        String((appModel.currentUser?.fullName ?? "H").prefix(1))
    }
}

private struct HostDetailBlock: View {
    let title: String
    let value: String

    private let theme = FestiveTabTheme.host

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(theme.accent.opacity(0.86))

            Text(value.isEmpty ? "Not set yet" : value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HostExperienceCard: View {
    @Environment(AppModel.self) private var appModel
    @State private var isAvailabilityPresented = false

    let experience: Experience

    private var style: ExperienceVisualStyle {
        ExperienceVisualStyle.make(for: experience)
    }

    private var lockedCount: Int {
        experience.slots.filter(\.hasActiveRequests).count
    }

    private var scheduleText: String? {
        guard let scheduleRange = experience.scheduleRange else { return nil }
        return scheduleRange.lowerBound.date(in: marketplaceCalendar).formatted(.dateTime.day().month())
        + " - "
        + scheduleRange.upperBound.date(in: marketplaceCalendar).formatted(.dateTime.day().month())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            .padding(20)
            .background(style.heroGradient)

            detailsSection
            .padding(20)
            .background(style.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(style.border.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: style.accent.opacity(0.10), radius: 18, y: 10)
        .sheet(isPresented: $isAvailabilityPresented) {
            ManageAvailabilitySheet(isPresented: $isAvailabilityPresented, experienceID: experience.id)
                .presentationDetents([.large])
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    FestiveTag(text: experience.mealType.title, fill: Color.white.opacity(0.2))
                    FestiveTag(text: experience.vibe.title, fill: Color.black.opacity(0.18))
                }

                Text(experience.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)

                Text(experience.cuisineOrigin)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
            }

            Spacer(minLength: 12)

            Text(experience.publishState.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.18), in: Capsule())
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            scheduleSummary

            Text(experience.description)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(style.ink)
                .fixedSize(horizontal: false, vertical: true)

            dateMetrics

            if let dietary = experience.dietarySupport.first {
                FestiveTag(text: dietary, fill: style.softTint, foreground: style.ink)
            }

            if !experience.spokenLanguages.isEmpty {
                FestiveTag(text: experience.spokenLanguages.joined(separator: " / "), fill: style.softTint.opacity(0.88), foreground: style.ink)
            }

            actionRow
        }
    }

    private var scheduleSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let nextStartAt = experience.nextStartAt {
                Label {
                    Text(nextStartAt, format: .dateTime.weekday(.abbreviated).day().month().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.ink.opacity(0.86))
            } else {
                Label("No currently bookable dates", systemImage: "calendar.badge.exclamationmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.ink.opacity(0.72))
            }

            if let scheduleText {
                Text(scheduleText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.accent)
            }

            if let serviceTime = experience.serviceTime {
                Text("Recurring start time: \(serviceTime, format: .dateTime.hour().minute())")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(style.ink.opacity(0.64))
            }
        }
    }

    private var dateMetrics: some View {
        HStack(spacing: 8) {
            FestiveTag(text: "\(experience.bookableSlots.count) open dates", fill: style.softTint, foreground: style.ink)
            FestiveTag(text: "\(experience.blockedDays.count) blocked", fill: style.softTint.opacity(0.86), foreground: style.ink)

            if lockedCount > 0 {
                FestiveTag(text: "\(lockedCount) locked", fill: Color.white.opacity(0.78), foreground: style.ink)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button("Manage Availability") {
                isAvailabilityPresented = true
            }
            .buttonStyle(FestiveActionButtonStyle(tint: Color.white.opacity(0.74), foreground: style.ink))
            .accessibilityIdentifier("host.manageAvailability")

            Button(experience.publishState == .published ? "Pause Listing" : "Publish Again") {
                Task {
                    await appModel.togglePublish(for: experience)
                }
            }
            .buttonStyle(FestiveActionButtonStyle(tint: experience.publishState == .published ? Color(red: 0.76, green: 0.35, blue: 0.25) : style.accent))
        }
    }
}

private struct CreateExperienceSheet: View {
    @Environment(AppModel.self) private var appModel
    @Binding var isPresented: Bool

    @State private var draft = ExperienceDraft()
    @State private var dietarySupport = ""
    @State private var spokenLanguages = ""

    private let theme = FestiveTabTheme.host
    private let selectionColumns = [GridItem(.adaptive(minimum: 128), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                FestiveMarketplaceBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        FestiveHeroCard(
                            theme: theme,
                            eyebrow: "Creator Studio",
                            title: "New Experience",
                            subtitle: "Set the tone, the place, and the dates before your table goes live."
                        )

                        FestiveSectionCard(theme: theme) {
                            FestiveSectionHeading(
                                theme: theme,
                                eyebrow: "Basics",
                                title: "Shape the experience",
                                subtitle: nil
                            )

                            StudioField(title: "Title", text: $draft.title, accessibilityIdentifier: "host.experience.title")
                            selectionSection(title: "Meal type") {
                                ForEach(ExperienceMealType.allCases) { mealType in
                                    FestiveChoicePill(
                                        title: mealType.title,
                                        isSelected: draft.mealType == mealType,
                                        theme: theme
                                    ) {
                                        draft.mealType = mealType
                                    }
                                }
                            }
                            selectionSection(title: "Vibe") {
                                ForEach(ExperienceVibe.allCases) { vibe in
                                    FestiveChoicePill(
                                        title: vibe.title,
                                        isSelected: draft.vibe == vibe,
                                        theme: theme
                                    ) {
                                        draft.vibe = vibe
                                    }
                                }
                            }
                            StudioField(title: "Cuisine origin", text: $draft.cuisineOrigin, accessibilityIdentifier: "host.experience.cuisine")
                            StudioField(title: "Description", text: $draft.description, axis: .vertical, accessibilityIdentifier: "host.experience.description")
                        }

                        FestiveSectionCard(theme: theme) {
                            FestiveSectionHeading(
                                theme: theme,
                                eyebrow: "Location",
                                title: "Where guests will gather",
                                subtitle: nil
                            )

                            StudioField(title: "City", text: $draft.city, accessibilityIdentifier: "host.experience.city")
                            StudioField(title: "Neighborhood", text: $draft.neighborhood, accessibilityIdentifier: "host.experience.neighborhood")
                            StudioField(title: "Full address", text: $draft.fullAddress, accessibilityIdentifier: "host.experience.address")
                            selectionSection(title: "Address privacy") {
                                FestiveChoicePill(
                                    title: "Reveal after acceptance",
                                    isSelected: draft.addressPrivacy == .neighborhoodOnly,
                                    theme: theme
                                ) {
                                    draft.addressPrivacy = .neighborhoodOnly
                                }
                                FestiveChoicePill(
                                    title: "Public on listing",
                                    isSelected: draft.addressPrivacy == .publicListing,
                                    theme: theme
                                ) {
                                    draft.addressPrivacy = .publicListing
                                }
                            }
                        }

                        FestiveSectionCard(theme: theme) {
                            FestiveSectionHeading(
                                theme: theme,
                                eyebrow: "Hosting Details",
                                title: "Set the rhythm of the table",
                                subtitle: "Choose a range, one recurring start time, and block the dates you already know are busy."
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Seats")
                                    .font(.caption.weight(.bold))
                                    .textCase(.uppercase)
                                    .foregroundStyle(theme.accent.opacity(0.84))

                                Stepper("Seats: \(draft.maxSeats)", value: $draft.maxSeats, in: 1...12)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(theme.border.opacity(0.64), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                Text("Availability range")
                                    .font(.caption.weight(.bold))
                                    .textCase(.uppercase)
                                    .foregroundStyle(theme.accent.opacity(0.84))

                                DatePicker(
                                    "Available from",
                                    selection: $draft.availableFrom,
                                    in: marketplaceCalendar.startOfDay(for: .now)...maximumStartDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(theme.border.opacity(0.64), lineWidth: 1)
                                )
                                .accessibilityIdentifier("host.schedule.start")

                                DatePicker(
                                    "Available until",
                                    selection: $draft.availableUntil,
                                    in: marketplaceCalendar.startOfDay(for: draft.availableFrom)...maximumEndDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(theme.border.opacity(0.64), lineWidth: 1)
                                )
                                .accessibilityIdentifier("host.schedule.end")

                                DatePicker(
                                    "Recurring time",
                                    selection: $draft.serviceTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(theme.border.opacity(0.64), lineWidth: 1)
                                )
                                .accessibilityIdentifier("host.schedule.time")
                            }

                            if let availabilityRange {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Blocked dates")
                                        .font(.caption.weight(.bold))
                                        .textCase(.uppercase)
                                        .foregroundStyle(theme.accent.opacity(0.84))

                                    AvailabilityLegend(
                                        accent: theme.accent,
                                        ink: theme.ink,
                                        softTint: theme.softTint,
                                        items: [
                                            ("Open", .available),
                                            ("Blocked", .blocked)
                                        ]
                                    )

                                    AvailabilityCalendarView(
                                        range: availabilityRange,
                                        accent: theme.accent,
                                        ink: theme.ink,
                                        softTint: theme.softTint,
                                        accessibilityRoot: "host.create.calendar",
                                        stateForDay: { dayKey in
                                            draft.blockedDays.contains(dayKey) ? .blocked : .available
                                        },
                                        canTapDay: { _, state in
                                            state != .outsideRange
                                        },
                                        onTapDay: { dayKey in
                                            toggleBlockedDay(dayKey)
                                        }
                                    )
                                    .accessibilityIdentifier("host.create.calendar")
                                    .padding(14)
                                    .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                }
                            }

                            StudioField(title: "Languages", prompt: "Comma separated", text: $spokenLanguages)
                            StudioField(title: "Dietary support", prompt: "Comma separated", text: $dietarySupport)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("New Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        draft.spokenLanguages = parseCSVList(spokenLanguages)
                        draft.dietarySupport = parseCSVList(dietarySupport)
                        Task {
                            await appModel.createExperience(draft: draft)
                            if appModel.errorMessage == nil {
                                isPresented = false
                            }
                        }
                    }
                    .accessibilityIdentifier("host.publishExperience")
                }
            }
            .task {
                if let hostProfile = appModel.hostProfile {
                    draft.city = hostProfile.homeCity
                    draft.neighborhood = hostProfile.neighborhood
                    spokenLanguages = hostProfile.spokenLanguages.joined(separator: ", ")
                } else if let currentUser = appModel.currentUser {
                    draft.city = currentUser.city
                }
            }
            .onChange(of: draft.availableFrom) { _, _ in
                normalizeRange()
            }
            .onChange(of: draft.availableUntil) { _, _ in
                normalizeRange()
            }
        }
    }

    private var maximumStartDate: Date {
        marketplaceCalendar.date(byAdding: .day, value: 89, to: marketplaceCalendar.startOfDay(for: .now))
        ?? defaultExperienceRangeEnd()
    }

    private var maximumEndDate: Date {
        marketplaceCalendar.date(byAdding: .day, value: 89, to: marketplaceCalendar.startOfDay(for: draft.availableFrom))
        ?? draft.availableFrom
    }

    private var availabilityRange: ClosedRange<DayKey>? {
        let start = DayKey(date: draft.availableFrom)
        let end = DayKey(date: draft.availableUntil)
        guard start <= end else { return nil }
        return start...end
    }

    private func selectionSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(theme.accent.opacity(0.84))

            LazyVGrid(columns: selectionColumns, alignment: .leading, spacing: 10) {
                content()
            }
        }
    }

    private func normalizeRange() {
        draft.availableFrom = marketplaceCalendar.startOfDay(for: draft.availableFrom)
        draft.availableUntil = marketplaceCalendar.startOfDay(for: draft.availableUntil)

        if draft.availableUntil < draft.availableFrom {
            draft.availableUntil = draft.availableFrom
        }

        if draft.availableUntil > maximumEndDate {
            draft.availableUntil = maximumEndDate
        }

        if let availabilityRange {
            draft.blockedDays = draft.blockedDays.filter { availabilityRange.contains($0) }
        } else {
            draft.blockedDays.removeAll()
        }
    }

    private func toggleBlockedDay(_ dayKey: DayKey) {
        if draft.blockedDays.contains(dayKey) {
            draft.blockedDays.remove(dayKey)
        } else {
            draft.blockedDays.insert(dayKey)
        }
    }
}

private struct StudioField: View {
    let title: String
    var prompt: String?
    @Binding var text: String
    var axis: Axis = .horizontal
    var accessibilityIdentifier: String?

    private let theme = FestiveTabTheme.host

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
                .accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
    }
}

private struct ManageAvailabilitySheet: View {
    @Environment(AppModel.self) private var appModel

    @Binding var isPresented: Bool
    let experienceID: UUID

    @State private var blockedDays: Set<DayKey> = []
    @State private var initialBlockedDays: Set<DayKey> = []

    private let theme = FestiveTabTheme.host

    private var experience: Experience? {
        appModel.hostExperiences.first(where: { $0.id == experienceID })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FestiveMarketplaceBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let experience else { return }
                        Task {
                            await appModel.updateBlockedDays(for: experience, blockedDays: blockedDays)
                            if appModel.errorMessage == nil {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(blockedDays == initialBlockedDays)
                    .accessibilityIdentifier("host.availability.save")
                }
            }
            .task(id: experienceID) {
                if let experience {
                    blockedDays = experience.blockedDays
                    initialBlockedDays = experience.blockedDays
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let experience, let scheduleRange = experience.scheduleRange {
            availabilityHero(for: experience, scheduleRange: scheduleRange)
            availabilityEditor(for: experience, scheduleRange: scheduleRange)
        } else {
            ContentUnavailableView("Experience Not Found", systemImage: "calendar.badge.exclamationmark")
        }
    }

    private func availabilityHero(for experience: Experience, scheduleRange: ClosedRange<DayKey>) -> some View {
        FestiveHeroCard(
            theme: theme,
            eyebrow: "Host Studio",
            title: "Manage Availability",
            subtitle: "Block dates when your home is busy. Dates with guest requests stay locked."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let serviceTime = experience.serviceTime {
                    FestiveMetricChip(
                        theme: theme,
                        value: serviceTime.formatted(.dateTime.hour().minute()),
                        label: "recurring time"
                    )
                }

                Text(
                    scheduleRange.lowerBound.date(in: marketplaceCalendar).formatted(.dateTime.day().month())
                    + " - "
                    + scheduleRange.upperBound.date(in: marketplaceCalendar).formatted(.dateTime.day().month())
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.90))
            }
        }
    }

    private func availabilityEditor(for experience: Experience, scheduleRange: ClosedRange<DayKey>) -> some View {
        FestiveSectionCard(theme: theme) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: "Calendar",
                title: "Toggle open and blocked dates",
                subtitle: "Locked dates already have pending or accepted guest requests."
            )

            AvailabilityLegend(
                accent: theme.accent,
                ink: theme.ink,
                softTint: theme.softTint,
                items: [
                    ("Open", .available),
                    ("Blocked", .blocked),
                    ("Locked", .locked)
                ]
            )

            AvailabilityCalendarView(
                range: scheduleRange,
                accent: theme.accent,
                ink: theme.ink,
                softTint: theme.softTint,
                accessibilityRoot: "host.manage.calendar",
                stateForDay: { dayKey in
                    calendarState(for: dayKey, in: experience)
                },
                canTapDay: { dayKey, state in
                    state != .outsideRange && !lockedDays(in: experience).contains(dayKey)
                },
                onTapDay: { dayKey in
                    toggleBlockedDay(dayKey)
                }
            )
            .accessibilityIdentifier("host.manage.calendar")
            .padding(14)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func calendarState(for dayKey: DayKey, in experience: Experience) -> AvailabilityCalendarDayState {
        if lockedDays(in: experience).contains(dayKey) {
            return .locked
        }

        if let _ = experience.slot(on: dayKey) {
            return blockedDays.contains(dayKey) ? .blocked : .available
        }

        return .outsideRange
    }

    private func lockedDays(in experience: Experience) -> Set<DayKey> {
        Set(experience.slots.filter(\.hasActiveRequests).map(\.dayKey))
    }

    private func toggleBlockedDay(_ dayKey: DayKey) {
        if blockedDays.contains(dayKey) {
            blockedDays.remove(dayKey)
        } else {
            blockedDays.insert(dayKey)
        }
    }
}

private struct FlowTagSection: View {
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

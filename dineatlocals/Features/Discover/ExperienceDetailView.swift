import SwiftUI

struct ExperienceDetailView: View {
    @Environment(AppModel.self) private var appModel

    let experienceID: UUID

    @State private var selectedDay: DayKey?
    @State private var seatsRequested = 2
    @State private var introMessage = ""
    @State private var guestNotes = ""
    @State private var heroSymbol = "fork.knife.circle.fill"
    @State private var galleryAssetNames: [String] = []
    @State private var selectedPhotoIndex = 0

    private var experience: Experience? {
        appModel.experiences.first(where: { $0.id == experienceID }) ??
        appModel.hostExperiences.first(where: { $0.id == experienceID })
    }

    var body: some View {
        Group {
            if let experience {
                ZStack {
                    FestiveMarketplaceBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            galleryHero(experience)
                            summaryCard(for: experience)
                            storyCard(for: experience)
                            logisticsCard(for: experience)
                            seatSelectionCard(for: experience)
                            requestComposer(for: experience)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                }
                .navigationTitle(experience.title)
                .navigationBarTitleDisplayMode(.inline)
                .task(id: experience.id) {
                    heroSymbol = await appModel.heroSymbol(for: experience)
                    galleryAssetNames = await appModel.galleryAssetNames(for: experience)
                    syncSelectedDay(with: experience)
                    clampSeats(for: experience)
                }
                .onChange(of: experience.slots) { _, _ in
                    syncSelectedDay(with: experience)
                    clampSeats(for: experience)
                }
                .onChange(of: selectedDay) { _, _ in
                    clampSeats(for: experience)
                }
            } else {
                ContentUnavailableView("Experience Not Found", systemImage: "fork.knife.circle")
            }
        }
    }

    private func galleryHero(_ experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)
        let gallery = galleryAssetNames.isEmpty
            ? ExperienceMediaCatalog.photoAssetNames(
                cuisineOrigin: experience.cuisineOrigin,
                vibe: experience.vibe,
                mealType: experience.mealType
            )
            : galleryAssetNames

        return ZStack(alignment: .bottomLeading) {
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(gallery.enumerated()), id: \.offset) { index, assetName in
                    ZStack {
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                        LinearGradient(
                            colors: [Color.black.opacity(0.05), Color.black.opacity(0.62)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .tag(index)
                }
            }
            .frame(height: 336)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    FestiveTag(text: experience.mealType.title, fill: Color.white.opacity(0.20))
                    FestiveTag(text: experience.vibe.title, fill: style.accent.opacity(0.92))
                }

                Text(experience.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 10) {
                    Image(systemName: heroSymbol)
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text("\(experience.cuisineOrigin) with \(experience.hostName)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            }
            .padding(24)
        }
        .overlay(alignment: .topTrailing) {
            Text("\(selectedPhotoIndex + 1)/\(gallery.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.20), in: Capsule())
                .padding(18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: style.accent.opacity(0.16), radius: 18, y: 12)
    }

    private func summaryCard(for experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)

        return DetailCard(title: "What This Table Feels Like", icon: "sparkles", style: style) {
            VStack(alignment: .leading, spacing: 14) {
                Text("A hosted \(experience.mealType.title.lowercased()) shaped around \(experience.cuisineOrigin.lowercased()), conversation, and a small-group table format.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(style.ink.opacity(0.86))

                VStack(alignment: .leading, spacing: 10) {
                    DetailFactRow(label: "Host", value: experience.hostName, tint: style.accent)
                    DetailFactRow(label: "Vibe", value: experience.vibe.title, tint: style.accent)
                    DetailFactRow(label: "Languages", value: experience.spokenLanguages.joinedForDisplay, tint: style.accent)
                    DetailFactRow(label: "Dietary support", value: experience.dietarySupport.joinedForDisplay, tint: style.accent)
                }
            }
        }
    }

    private func storyCard(for experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)

        return DetailCard(title: "Story And Menu", icon: "book.pages.fill", style: style) {
            Text(experience.description)
                .font(.body)
                .foregroundStyle(style.ink.opacity(0.9))
        }
    }

    private func logisticsCard(for experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)
        let visibleAddress = appModel.visibleAddress(for: experience)

        return DetailCard(title: "Time And Place", icon: "mappin.and.ellipse", style: style) {
            VStack(alignment: .leading, spacing: 12) {
                DetailFactRow(label: "City", value: experience.city, tint: style.accent)
                DetailFactRow(label: "Neighborhood", value: experience.neighborhood, tint: style.accent)
                DetailFactRow(label: "Address", value: visibleAddress, tint: style.accent)

                if visibleAddress != experience.fullAddress {
                    Text("Exact address appears after the booking request is accepted.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(style.ink.opacity(0.65))
                        .padding(.top, 2)
                }
            }
        }
    }

    private func seatSelectionCard(for experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)

        return DetailCard(title: "Choose Your Date", icon: "calendar.badge.clock", style: style) {
            if let scheduleRange = experience.scheduleRange {
                VStack(alignment: .leading, spacing: 14) {
                    AvailabilityLegend(
                        accent: style.accent,
                        ink: style.ink,
                        softTint: style.softTint,
                        items: [
                            ("Open", .available),
                            ("Selected", .selected),
                            ("Blocked", .blocked),
                            ("Full", .full)
                        ]
                    )

                    AvailabilityCalendarView(
                        range: scheduleRange,
                        accent: style.accent,
                        ink: style.ink,
                        softTint: style.softTint,
                        accessibilityRoot: "experience.detail.calendar",
                        stateForDay: { dayKey in
                            calendarState(for: dayKey, in: experience)
                        },
                        canTapDay: { _, state in
                            state == .available || state == .selected
                        },
                        onTapDay: { dayKey in
                            selectedDay = dayKey
                        }
                    )
                    .padding(14)
                    .background(Color.white.opacity(0.60), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityIdentifier("experience.detail.calendar")

                    if let selectedSlot = selectedSlot(for: experience) {
                        VStack(alignment: .leading, spacing: 10) {
                            DetailFactRow(
                                label: "Selected date",
                                value: selectedSlot.startAt.formatted(.dateTime.weekday(.wide).day().month()),
                                tint: style.accent
                            )
                            DetailFactRow(
                                label: "Recurring time",
                                value: selectedSlot.startAt.formatted(.dateTime.hour().minute()),
                                tint: style.accent
                            )
                            DetailFactRow(
                                label: "Seats left",
                                value: "\(selectedSlot.remainingSeats) of \(selectedSlot.seatCapacity)",
                                tint: style.accent
                            )
                        }
                    } else if experience.bookableSlots.isEmpty {
                        Text("The current range is either fully booked or blocked. Check back when the host reopens dates.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(style.ink.opacity(0.72))
                    }
                }
            } else {
                Text("This experience does not have a calendar yet.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(style.ink.opacity(0.68))
            }
        }
    }

    private func requestComposer(for experience: Experience) -> some View {
        let style = ExperienceVisualStyle.make(for: experience)
        let selectedSlot = selectedSlot(for: experience)

        return DetailCard(title: "Request A Seat", icon: "paperplane.fill", style: style) {
            if appModel.canCurrentUserRequest(experience) {
                if experience.bookableSlots.isEmpty {
                    Text("No dates are currently open for requests.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(style.ink.opacity(0.68))
                } else if let selectedSlot {
                    let maximumSeats = max(1, min(selectedSlot.remainingSeats, experience.maxSeats))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Selected: \(selectedSlot.startAt, format: .dateTime.weekday(.wide).day().month().hour().minute())")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(style.ink.opacity(0.8))

                        Stepper("Seats: \(seatsRequested)", value: $seatsRequested, in: 1...maximumSeats)
                            .font(.subheadline.weight(.semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intro message")
                                .font(.subheadline.weight(.bold))
                            TextField("Tell the host why this table fits you", text: $introMessage, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dietary or accessibility notes")
                                .font(.subheadline.weight(.bold))
                            TextField("Optional notes for the host", text: $guestNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            Task {
                                await appModel.submitBookingRequest(
                                    experience: experience,
                                    slotID: selectedSlot.id,
                                    seatsRequested: seatsRequested,
                                    introMessage: introMessage,
                                    guestNotes: guestNotes
                                )
                            }
                        } label: {
                            Label("Send Booking Request", systemImage: "paperplane.fill")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(style.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("experience.request.submit")
                    }
                } else {
                    Text("Choose an available date from the calendar before sending a request.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(style.ink.opacity(0.68))
                }
            } else {
                Text("You are the host for this experience, so the guest booking composer is hidden.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(style.ink.opacity(0.68))
            }
        }
    }

    private func calendarState(for dayKey: DayKey, in experience: Experience) -> AvailabilityCalendarDayState {
        guard let slot = experience.slot(on: dayKey) else {
            return .outsideRange
        }

        if selectedDay == dayKey {
            return .selected
        }

        if slot.manualAvailability == .blockedByHost || slot.startAt < .now {
            return .blocked
        }

        if slot.isFull {
            return .full
        }

        return .available
    }

    private func selectedSlot(for experience: Experience) -> ExperienceSlot? {
        guard let selectedDay else { return nil }
        return experience.slot(on: selectedDay)
    }

    private func syncSelectedDay(with experience: Experience) {
        if let selectedDay,
           let slot = experience.slot(on: selectedDay),
           slot.isBookable {
            return
        }

        selectedDay = experience.bookableSlots.first?.dayKey
    }

    private func clampSeats(for experience: Experience) {
        if let selectedSlot = selectedSlot(for: experience) {
            let maximumSeats = max(1, min(selectedSlot.remainingSeats, experience.maxSeats))
            if seatsRequested > maximumSeats {
                seatsRequested = maximumSeats
            }
        } else if seatsRequested > experience.maxSeats {
            seatsRequested = experience.maxSeats
        }
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    let style: ExperienceVisualStyle
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(style.accent)
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(style.ink)
            }

            content
        }
        .padding(20)
        .background(style.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(style.border.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: style.accent.opacity(0.10), radius: 14, y: 8)
    }
}

private struct DetailFactRow: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

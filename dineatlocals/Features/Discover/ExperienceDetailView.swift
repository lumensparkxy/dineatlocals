import SwiftUI

struct ExperienceDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let experienceID: UUID

    @State private var selectedDay: DayKey?
    @State private var seatsRequested = 2
    @State private var introMessage = ""
    @State private var guestNotes = ""
    @State private var galleryAssetNames: [String] = []
    @State private var selectedPhotoIndex = 0
    @State private var isSaved = false
    @State private var isCalendarPresented = false
    @State private var isRequestPresented = false

    private var experience: Experience? {
        appModel.experiences.first(where: { $0.id == experienceID }) ??
        appModel.hostExperiences.first(where: { $0.id == experienceID })
    }

    var body: some View {
        Group {
            if let experience {
                ZStack(alignment: .bottom) {
                    FestiveMarketplaceBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            galleryHero(experience)
                            overviewSection(for: experience)
                            trustStrip(for: experience)
                            storySection(for: experience)
                            dateSelectionSection(for: experience)
                            logisticsSection(for: experience)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, appModel.canCurrentUserRequest(experience) ? 124 : 34)
                        .festiveReadableColumn(maxWidth: 980)
                    }

                    if appModel.canCurrentUserRequest(experience) {
                        bottomRequestBar(for: experience)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $isCalendarPresented) {
                    calendarSheet(for: experience)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $isRequestPresented) {
                    requestSheet(for: experience)
                        .presentationDetents([.large])
                }
                .task(id: experience.id) {
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
        let gallery = activeGallery(for: experience)

        return ZStack(alignment: .top) {
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(gallery.enumerated()), id: \.offset) { index, assetName in
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .frame(height: 306)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                LinearGradient(
                    colors: [Color.black.opacity(0.28), Color.clear, Color.black.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SupperClubPalette.ink)
                        .frame(width: 50, height: 50)
                        .background(SupperClubPalette.paper.opacity(0.94), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(SupperClubPalette.oxblood)
                        .frame(width: 50, height: 50)
                        .background(SupperClubPalette.paper.opacity(0.94), in: Circle())
                }
                .buttonStyle(.plain)

                ShareLink(item: "\(experience.title) on DineAtLocals") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(SupperClubPalette.ink)
                        .frame(width: 50, height: 50)
                        .background(SupperClubPalette.paper.opacity(0.94), in: Circle())
                }
            }
            .padding(14)
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(selectedPhotoIndex + 1) / \(activeGallery(for: experience).count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .padding(16)
        }
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.12), radius: 16, y: 9)
    }

    private func overviewSection(for experience: Experience) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(experience.title)
                .font(.system(size: 42, weight: .semibold, design: .serif))
                .foregroundStyle(SupperClubPalette.oxblood)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 14) {
                Text(String(experience.hostName.prefix(1)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(SupperClubPalette.sage, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hosted by \(experience.hostName)")
                        .font(.headline)
                        .foregroundStyle(SupperClubPalette.ink)
                    Text("\(experience.neighborhood), \(experience.city)")
                        .font(.subheadline)
                        .foregroundStyle(SupperClubPalette.muted)
                }

                Spacer()

                TrustBadge(title: "Verified Host", icon: "checkmark.shield.fill")
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
                if let selectedSlot = selectedSlot(for: experience) {
                    DetailSummaryItem(
                        icon: "calendar",
                        title: "Next table",
                        value: selectedSlot.startAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
                    )
                    DetailSummaryItem(
                        icon: "person.2",
                        title: "\(selectedSlot.remainingSeats) seats left",
                        value: "Max \(selectedSlot.seatCapacity) guests"
                    )
                } else {
                    DetailSummaryItem(icon: "calendar.badge.exclamationmark", title: "Next table", value: "No open dates")
                    DetailSummaryItem(icon: "person.2", title: "Small table", value: "Max \(experience.maxSeats) guests")
                }
            }
        }
    }

    private func trustStrip(for experience: Experience) -> some View {
        let visibleAddress = appModel.visibleAddress(for: experience)
        let addressText = visibleAddress == experience.fullAddress
            ? visibleAddress
            : "Exact address shared after acceptance"

        return VStack(spacing: 0) {
            Divider()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 18) {
                TrustFact(icon: "lock", text: addressText)
                TrustFact(icon: "bubble.left", text: experience.spokenLanguages.joinedForDisplay)
                TrustFact(icon: "leaf", text: experience.dietarySupport.first ?? "Flexible menu")
                TrustFact(icon: "person.2", text: "Max \(experience.maxSeats) guests")
            }
            .padding(.vertical, 18)
            Divider()
        }
    }

    private func storySection(for experience: Experience) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Around the table")
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(SupperClubPalette.oxblood)

            Text(experience.description)
                .font(.body)
                .lineSpacing(4)
                .foregroundStyle(SupperClubPalette.ink.opacity(0.86))

            Text(hostSignature(for: experience.hostName))
                .font(.system(size: 22, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(SupperClubPalette.sage)
                .padding(.top, 4)
        }
    }

    private func dateSelectionSection(for experience: Experience) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Choose a date")
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .foregroundStyle(SupperClubPalette.oxblood)

                Spacer()

                Button {
                    isCalendarPresented = true
                } label: {
                    Label("View all dates", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SupperClubPalette.ink)
                }
                .buttonStyle(.plain)
            }

            if experience.bookableSlots.isEmpty {
                Text("This table has no open dates right now. Check back after the host reopens availability.")
                    .font(.subheadline)
                    .foregroundStyle(SupperClubPalette.muted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SupperClubPalette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SupperClubPalette.border, lineWidth: 1)
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(experience.bookableSlots.prefix(8))) { slot in
                            DateSelectionPill(
                                slot: slot,
                                isSelected: selectedDay == slot.dayKey
                            ) {
                                selectedDay = slot.dayKey
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func logisticsSection(for experience: Experience) -> some View {
        let visibleAddress = appModel.visibleAddress(for: experience)

        return DetailCard(title: "Time and place", icon: "mappin.and.ellipse", style: ExperienceVisualStyle.make(for: experience)) {
            VStack(alignment: .leading, spacing: 12) {
                DetailFactRow(label: "City", value: experience.city, tint: SupperClubPalette.oxblood)
                DetailFactRow(label: "Neighborhood", value: experience.neighborhood, tint: SupperClubPalette.oxblood)
                DetailFactRow(label: "Address", value: visibleAddress, tint: SupperClubPalette.oxblood)

                if visibleAddress != experience.fullAddress {
                    Text("The host shares the exact address only after accepting your request.")
                        .font(.caption)
                        .foregroundStyle(SupperClubPalette.muted)
                }
            }
        }
    }

    private func bottomRequestBar(for experience: Experience) -> some View {
        VStack(spacing: 10) {
            Button {
                isRequestPresented = true
            } label: {
                Text(experience.bookableSlots.isEmpty ? "No dates available" : "Request a seat")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        experience.bookableSlots.isEmpty ? SupperClubPalette.muted.opacity(0.45) : SupperClubPalette.aubergine,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(experience.bookableSlots.isEmpty)
            .accessibilityIdentifier("experience.detail.request")

            Label("No payment now. Seats are confirmed by the host.", systemImage: "checkmark.shield.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(SupperClubPalette.sage)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.10), radius: 16, y: -6)
    }

    private func calendarSheet(for experience: Experience) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("All available dates")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(SupperClubPalette.oxblood)

                    if let scheduleRange = experience.scheduleRange {
                        AvailabilityLegend(
                            accent: SupperClubPalette.oxblood,
                            ink: SupperClubPalette.ink,
                            softTint: SupperClubPalette.blush,
                            items: [
                                ("Open", .available),
                                ("Selected", .selected),
                                ("Blocked", .blocked),
                                ("Full", .full)
                            ]
                        )

                        AvailabilityCalendarView(
                            range: scheduleRange,
                            accent: SupperClubPalette.oxblood,
                            ink: SupperClubPalette.ink,
                            softTint: SupperClubPalette.blush,
                            accessibilityRoot: "experience.detail.calendar",
                            stateForDay: { dayKey in
                                calendarState(for: dayKey, in: experience)
                            },
                            canTapDay: { _, state in
                                state == .available || state == .selected
                            },
                            onTapDay: { dayKey in
                                selectedDay = dayKey
                                isCalendarPresented = false
                            }
                        )
                        .padding(14)
                        .background(SupperClubPalette.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(SupperClubPalette.border, lineWidth: 1)
                        )
                        .accessibilityIdentifier("experience.detail.calendar")
                    }
                }
                .padding(20)
            }
            .background(FestiveMarketplaceBackground())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isCalendarPresented = false
                    }
                }
            }
        }
    }

    private func requestSheet(for experience: Experience) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Request a seat")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(SupperClubPalette.oxblood)
                        .accessibilityIdentifier("experience.request.sheet")

                    requestComposer(for: experience)
                }
                .padding(20)
            }
            .accessibilityIdentifier("experience.request.scroll")
            .background(FestiveMarketplaceBackground())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isRequestPresented = false
                    }
                }
            }
        }
    }

    private func requestComposer(for experience: Experience) -> some View {
        let selectedSlot = selectedSlot(for: experience)

        return DetailCard(title: "Booking request", icon: "paperplane.fill", style: ExperienceVisualStyle.make(for: experience)) {
            if experience.bookableSlots.isEmpty {
                Text("No dates are currently open for requests.")
                    .font(.subheadline)
                    .foregroundStyle(SupperClubPalette.muted)
            } else if let selectedSlot {
                let maximumSeats = max(1, min(selectedSlot.remainingSeats, experience.maxSeats))

                VStack(alignment: .leading, spacing: 18) {
                    DetailFactRow(
                        label: "Selected date",
                        value: selectedSlot.startAt.formatted(.dateTime.weekday(.wide).day().month().hour().minute()),
                        tint: SupperClubPalette.oxblood
                    )

                    HStack(spacing: 12) {
                        Text("Seats")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(SupperClubPalette.ink)

                        Spacer()

                        Button {
                            seatsRequested = max(1, seatsRequested - 1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(SupperClubPalette.paper, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(SupperClubPalette.ink)
                        .disabled(seatsRequested <= 1)
                        .accessibilityLabel("Decrease seats")
                        .accessibilityIdentifier("experience.request.seats.decrement")

                        Text("Seats: \(seatsRequested)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SupperClubPalette.ink)
                            .frame(minWidth: 72)
                            .accessibilityIdentifier("experience.request.seats.value")

                        Button {
                            seatsRequested = min(maximumSeats, seatsRequested + 1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(SupperClubPalette.paper, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(SupperClubPalette.ink)
                        .disabled(seatsRequested >= maximumSeats)
                        .accessibilityLabel("Increase seats")
                        .accessibilityIdentifier("experience.request.seats.increment")
                    }
                    .padding(14)
                    .background(SupperClubPalette.paperWarm.opacity(0.65), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("experience.request.seats.stepper")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intro message")
                            .font(.subheadline.weight(.bold))
                        TextField("Tell the host why this table fits you", text: $introMessage, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier("experience.request.intro")
                            .festiveInputSurface(theme: .requests)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dietary or accessibility notes")
                            .font(.subheadline.weight(.bold))
                        TextField("Optional notes for the host", text: $guestNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier("experience.request.notes")
                            .festiveInputSurface(theme: .requests)
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
                            if appModel.errorMessage == nil {
                                isRequestPresented = false
                            }
                        }
                    } label: {
                        Label("Request a seat", systemImage: "paperplane.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FestiveActionButtonStyle(tint: SupperClubPalette.aubergine))
                    .accessibilityIdentifier("experience.request.submit")
                }
            } else {
                Text("Choose an available date before sending a request.")
                    .font(.subheadline)
                    .foregroundStyle(SupperClubPalette.muted)
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

    private func activeGallery(for experience: Experience) -> [String] {
        galleryAssetNames.isEmpty
            ? ExperienceMediaCatalog.photoAssetNames(
                cuisineOrigin: experience.cuisineOrigin,
                vibe: experience.vibe,
                mealType: experience.mealType
            )
            : galleryAssetNames
    }

    private func hostSignature(for hostName: String) -> String {
        "A presto, \(hostName.split(separator: " ").first.map(String.init) ?? hostName)"
    }
}

private struct TrustBadge: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(SupperClubPalette.sage)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.89, green: 0.92, blue: 0.84), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct DetailSummaryItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.medium))
                .foregroundStyle(SupperClubPalette.sage)
                .frame(width: 38, height: 38)
                .background(SupperClubPalette.paperWarm.opacity(0.75), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SupperClubPalette.ink)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(SupperClubPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct TrustFact: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.headline.weight(.medium))
                .foregroundStyle(SupperClubPalette.sage)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(SupperClubPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DateSelectionPill: View {
    let slot: ExperienceSlot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(slot.startAt, format: .dateTime.weekday(.abbreviated))
                    .font(.caption.weight(.semibold))
                Text(slot.startAt, format: .dateTime.day().month())
                    .font(.subheadline.weight(.bold))
                Text(slot.startAt, format: .dateTime.hour().minute())
                    .font(.caption)
                if slot.remainingSeats <= 3 {
                    Text("\(slot.remainingSeats) left")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.88) : SupperClubPalette.sage)
                }
            }
            .foregroundStyle(isSelected ? .white : SupperClubPalette.ink)
            .frame(width: 112, height: 92)
            .background(isSelected ? SupperClubPalette.oxblood : SupperClubPalette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? SupperClubPalette.oxblood : SupperClubPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(style.ink)
            }

            content
        }
        .padding(18)
        .background(style.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.border, lineWidth: 1)
        )
        .shadow(color: SupperClubPalette.warmShadow.opacity(0.04), radius: 10, y: 5)
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
                .foregroundStyle(SupperClubPalette.ink)
        }
    }
}

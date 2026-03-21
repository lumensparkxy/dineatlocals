import Foundation

actor MockMarketplaceStore: AuthService, ProfileService, ExperienceService, BookingService, ModerationService, MediaService {
    private var currentUserID: UUID
    private var users: [UUID: UserAccount]
    private var guestProfiles: [UUID: GuestProfile]
    private var hostProfiles: [UUID: HostProfile]
    private var experiences: [UUID: Experience]
    private var bookingRequests: [UUID: BookingRequest]
    private var moderationRecords: [UUID: [AdminReviewRecord]]

    init(seed: SeedData = .mock()) {
        currentUserID = seed.currentUserID
        users = seed.users
        guestProfiles = seed.guestProfiles
        hostProfiles = seed.hostProfiles
        experiences = seed.experiences
        bookingRequests = seed.bookingRequests
        moderationRecords = seed.moderationRecords
    }

    func currentUser() async throws -> UserAccount {
        guard let user = users[currentUserID] else {
            throw MarketplaceError.unauthorizedAction
        }

        return user
    }

    func fetchGuestProfile(userID: UUID) async throws -> GuestProfile {
        guard let profile = guestProfiles[userID] else {
            throw MarketplaceError.unauthorizedAction
        }

        return profile
    }

    func fetchHostProfile(userID: UUID) async throws -> HostProfile? {
        hostProfiles[userID]
    }

    func updateGuestProfile(_ profile: GuestProfile) async throws -> GuestProfile {
        guard guestProfiles[profile.userID] != nil else {
            throw MarketplaceError.unauthorizedAction
        }

        guestProfiles[profile.userID] = profile
        return profile
    }

    func submitHostProfile(_ profile: HostProfile) async throws -> HostProfile {
        var submittedProfile = profile

        if submittedProfile.approvalStatus == .notApplied {
            submittedProfile.approvalStatus = .pendingReview
        }

        hostProfiles[profile.userID] = submittedProfile

        if moderationRecords[profile.userID] == nil {
            moderationRecords[profile.userID] = []
        }

        moderationRecords[profile.userID]?.append(
            AdminReviewRecord(
                id: UUID(),
                hostUserID: profile.userID,
                reviewerName: "Ops Team",
                status: submittedProfile.approvalStatus,
                note: "Profile submitted and queued for manual trust review.",
                reviewedAt: .now
            )
        )

        return submittedProfile
    }

    func catalogCities() async throws -> [String] {
        Array(Set(experiences.values.map(\.city))).sorted()
    }

    func discoverExperiences(filter: ExperienceFilter) async throws -> [Experience] {
        experiences.values
            .filter { $0.publishState == .published }
            .map(liveExperience)
            .filter { experience in
                if let city = filter.city, experience.city != city {
                    return false
                }

                if let mealType = filter.mealType, experience.mealType != mealType {
                    return false
                }

                if let vibe = filter.vibe, experience.vibe != vibe {
                    return false
                }

                let searchText = filter.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !searchText.isEmpty else { return true }

                let haystack = [
                    experience.title,
                    experience.cuisineOrigin,
                    experience.city,
                    experience.hostName,
                    experience.description
                ]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(searchText)

                return haystack
            }
            .sorted { sortDate(for: $0) < sortDate(for: $1) }
    }

    func hostExperiences(hostID: UUID) async throws -> [Experience] {
        experiences.values
            .filter { $0.hostID == hostID }
            .map(liveExperience)
            .sorted { sortDate(for: $0) < sortDate(for: $1) }
    }

    func createExperience(draft: ExperienceDraft, hostID: UUID) async throws -> Experience {
        try MarketplaceValidation.ensureHostCanPublish(hostProfiles[hostID])
        try MarketplaceValidation.ensureValidDraft(draft)

        guard let hostUser = users[hostID] else {
            throw MarketplaceError.unauthorizedAction
        }

        let experience = Experience(
            id: UUID(),
            hostID: hostID,
            hostName: hostUser.fullName,
            title: draft.title,
            mealType: draft.mealType,
            vibe: draft.vibe,
            cuisineOrigin: draft.cuisineOrigin,
            description: draft.description,
            city: draft.city,
            neighborhood: draft.neighborhood,
            fullAddress: draft.fullAddress,
            addressPrivacy: draft.addressPrivacy,
            maxSeats: draft.maxSeats,
            dietarySupport: draft.dietarySupport,
            spokenLanguages: draft.spokenLanguages,
            photoAssetNames: ExperienceMediaCatalog.photoAssetNames(
                cuisineOrigin: draft.cuisineOrigin,
                vibe: draft.vibe,
                mealType: draft.mealType
            ),
            publishState: .published,
            slots: materializeSlots(
                availableFrom: draft.availableFrom,
                availableUntil: draft.availableUntil,
                serviceTime: draft.serviceTime,
                seatCapacity: draft.maxSeats,
                blockedDays: draft.blockedDays
            )
        )

        experiences[experience.id] = experience
        return liveExperience(experience)
    }

    func setPublishState(_ state: ExperiencePublishState, for experienceID: UUID, hostID: UUID) async throws -> Experience {
        guard var experience = experiences[experienceID] else {
            throw MarketplaceError.experienceUnavailable
        }

        guard experience.hostID == hostID else {
            throw MarketplaceError.unauthorizedAction
        }

        if state == .published {
            try MarketplaceValidation.ensureHostCanPublish(hostProfiles[hostID])
        }

        experience.publishState = state
        experiences[experienceID] = experience
        return liveExperience(experience)
    }

    func updateBlockedDays(_ blockedDays: Set<DayKey>, for experienceID: UUID, hostID: UUID) async throws -> Experience {
        guard var experience = experiences[experienceID] else {
            throw MarketplaceError.experienceUnavailable
        }

        guard experience.hostID == hostID else {
            throw MarketplaceError.unauthorizedAction
        }

        let slotDayKeys = Set(experience.slots.map(\.dayKey))
        guard blockedDays.isSubset(of: slotDayKeys) else {
            throw MarketplaceError.invalidDraft("Blocked dates need to stay inside the existing range.")
        }

        guard blockedDays.count < slotDayKeys.count else {
            throw MarketplaceError.invalidDraft("Leave at least one available date in the range.")
        }

        let enrichedExperience = liveExperience(experience)
        let newlyBlockedDays = blockedDays.subtracting(enrichedExperience.blockedDays)
        let lockedDays = Set(
            enrichedExperience.slots
                .filter(\.hasActiveRequests)
                .map(\.dayKey)
        )

        guard newlyBlockedDays.isDisjoint(with: lockedDays) else {
            throw MarketplaceError.busyDateCannotBeBlocked
        }

        experience.slots = experience.slots.map { slot in
            var updatedSlot = slot
            updatedSlot.manualAvailability = blockedDays.contains(slot.dayKey) ? .blockedByHost : .available
            return updatedSlot
        }

        experiences[experienceID] = experience
        return liveExperience(experience)
    }

    func guestRequests(userID: UUID) async throws -> [BookingRequest] {
        bookingRequests.values
            .filter { $0.guestID == userID }
            .sorted { $0.slotStartAt < $1.slotStartAt }
    }

    func hostRequests(hostID: UUID) async throws -> [BookingRequest] {
        bookingRequests.values
            .filter { $0.hostID == hostID }
            .sorted { $0.slotStartAt < $1.slotStartAt }
    }

    func submitRequest(draft: BookingRequestDraft, guestID: UUID) async throws -> BookingRequest {
        guard let experience = experiences[draft.experienceID], experience.publishState == .published else {
            throw MarketplaceError.experienceUnavailable
        }

        guard experience.hostID != guestID else {
            throw MarketplaceError.hostCannotBookOwnExperience
        }

        guard let slot = experience.slots.first(where: { $0.id == draft.slotID }) else {
            throw MarketplaceError.missingSlot
        }

        guard slot.manualAvailability == .available, slot.startAt >= .now else {
            throw MarketplaceError.experienceUnavailable
        }

        let activeSeats = activeSeats(for: slot.id)

        try MarketplaceValidation.ensureSeatCapacity(
            requestedSeats: draft.seatsRequested,
            slotCapacity: slot.seatCapacity,
            activeSeats: activeSeats
        )

        guard let guestUser = users[guestID] else {
            throw MarketplaceError.unauthorizedAction
        }

        let request = BookingRequest(
            id: UUID(),
            experienceID: experience.id,
            experienceTitle: experience.title,
            hostID: experience.hostID,
            hostName: experience.hostName,
            guestID: guestID,
            guestName: guestUser.fullName,
            slotID: slot.id,
            slotStartAt: slot.startAt,
            seatsRequested: draft.seatsRequested,
            introMessage: draft.introMessage,
            guestNotes: draft.guestNotes,
            status: .pending
        )

        bookingRequests[request.id] = request
        return request
    }

    func updateRequestStatus(_ status: RequestStatus, requestID: UUID, actorID: UUID) async throws -> BookingRequest {
        guard var request = bookingRequests[requestID] else {
            throw MarketplaceError.requestNotFound
        }

        try MarketplaceValidation.ensureTransition(from: request.status, to: status)

        let isHostAction = request.hostID == actorID
        let isGuestAction = request.guestID == actorID

        switch status {
        case .accepted, .declined, .completed:
            guard isHostAction else {
                throw MarketplaceError.unauthorizedAction
            }
        case .cancelled:
            guard isHostAction || isGuestAction else {
                throw MarketplaceError.unauthorizedAction
            }
        case .pending:
            throw MarketplaceError.invalidRequestTransition
        }

        if status == .accepted {
            guard let experience = experiences[request.experienceID] else {
                throw MarketplaceError.experienceUnavailable
            }

            guard let slot = experience.slots.first(where: { $0.id == request.slotID }) else {
                throw MarketplaceError.missingSlot
            }

            guard slot.manualAvailability == .available, slot.startAt >= .now else {
                throw MarketplaceError.experienceUnavailable
            }

            let activeSeats = bookingRequests.values
                .filter { $0.slotID == slot.id && $0.id != request.id && ($0.status == .pending || $0.status == .accepted) }
                .map(\.seatsRequested)
                .reduce(0, +)

            try MarketplaceValidation.ensureSeatCapacity(
                requestedSeats: request.seatsRequested,
                slotCapacity: slot.seatCapacity,
                activeSeats: activeSeats
            )
        }

        request.status = status
        bookingRequests[requestID] = request
        return request
    }

    func fetchHostReviews(hostID: UUID) async throws -> [AdminReviewRecord] {
        moderationRecords[hostID, default: []]
            .sorted { $0.reviewedAt > $1.reviewedAt }
    }

    func heroSymbol(for experience: Experience) async -> String {
        switch experience.vibe {
        case .familyStyle:
            "person.3.sequence.fill"
        case .storytelling:
            "book.closed.fill"
        case .chefTable:
            "fork.knife.circle.fill"
        case .festive:
            "sparkles"
        }
    }

    func galleryAssetNames(for experience: Experience) async -> [String] {
        if experience.photoAssetNames.isEmpty {
            return ExperienceMediaCatalog.photoAssetNames(
                cuisineOrigin: experience.cuisineOrigin,
                vibe: experience.vibe,
                mealType: experience.mealType
            )
        }

        return experience.photoAssetNames
    }

    private func liveExperience(_ experience: Experience) -> Experience {
        var enrichedExperience = experience
        enrichedExperience.slots = enrichedExperience.slots
            .map { slot in
                var updatedSlot = slot
                updatedSlot.activeSeats = activeSeats(for: slot.id)
                return updatedSlot
            }
            .sorted { $0.startAt < $1.startAt }

        return enrichedExperience
    }

    private func activeSeats(for slotID: UUID) -> Int {
        bookingRequests.values
            .filter { $0.slotID == slotID && ($0.status == .pending || $0.status == .accepted) }
            .map(\.seatsRequested)
            .reduce(0, +)
    }

    private func sortDate(for experience: Experience) -> Date {
        experience.nextStartAt
        ?? experience.slots.map(\.startAt).sorted().first
        ?? .distantFuture
    }
}

extension MockMarketplaceStore {
    struct SeedData {
        var currentUserID: UUID
        var users: [UUID: UserAccount]
        var guestProfiles: [UUID: GuestProfile]
        var hostProfiles: [UUID: HostProfile]
        var experiences: [UUID: Experience]
        var bookingRequests: [UUID: BookingRequest]
        var moderationRecords: [UUID: [AdminReviewRecord]]

        static func mock(now: Date = .now) -> SeedData {
            let calendar = marketplaceCalendar
            let baseNow = calendar.startOfDay(for: now)

            func day(after offset: Int) -> Date {
                calendar.date(byAdding: .day, value: offset, to: baseNow) ?? baseNow
            }

            func dayKey(after offset: Int) -> DayKey {
                DayKey(date: day(after: offset), calendar: calendar)
            }

            let currentUserID = UUID(uuidString: "A8CC5F3C-6F10-4A4B-B311-804A8B72AB1E") ?? UUID()
            let elenaID = UUID(uuidString: "AECA841F-67E3-4F3D-B057-9A50A1C7308E") ?? UUID()
            let kenjiID = UUID(uuidString: "48742CC4-8B87-4E19-9EA4-44FE211D0288") ?? UUID()
            let julesID = UUID(uuidString: "F3B1A43A-7A17-4F10-B866-A6B2A53EE851") ?? UUID()
            let amiraID = UUID(uuidString: "C29FD0BC-5420-4E88-84E5-7E1AE1D0C90A") ?? UUID()
            let sofiaID = UUID(uuidString: "F524C5F0-9881-440F-983F-E6B476C856A9") ?? UUID()
            let malikID = UUID(uuidString: "7CD3842B-BBC8-4CC7-A471-BC956594A12D") ?? UUID()
            let leilaID = UUID(uuidString: "F506A6D0-AE52-4212-8C55-C8C3EEE8B6CE") ?? UUID()
            let tobiasID = UUID(uuidString: "B53771FE-7E7A-4B85-B355-BDA63F1551A0") ?? UUID()
            let noraID = UUID(uuidString: "61A4A892-3DBD-4431-9775-85A6D0E6422F") ?? UUID()

            let users: [UUID: UserAccount] = [
                currentUserID: UserAccount(
                    id: currentUserID,
                    fullName: "Aarav Menon",
                    email: "aarav@dineatlocals.app",
                    city: "Zurich",
                    localeIdentifier: "en_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                elenaID: UserAccount(
                    id: elenaID,
                    fullName: "Elena Rossi",
                    email: "elena@example.com",
                    city: "Zurich",
                    localeIdentifier: "it_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                kenjiID: UserAccount(
                    id: kenjiID,
                    fullName: "Kenji Sato",
                    email: "kenji@example.com",
                    city: "Basel",
                    localeIdentifier: "ja_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                julesID: UserAccount(
                    id: julesID,
                    fullName: "Jules Martin",
                    email: "jules@example.com",
                    city: "Bern",
                    localeIdentifier: "fr_CH",
                    roles: [.guest],
                    verificationState: .emailVerified
                ),
                amiraID: UserAccount(
                    id: amiraID,
                    fullName: "Amira Haddad",
                    email: "amira@example.com",
                    city: "Geneva",
                    localeIdentifier: "fr_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                sofiaID: UserAccount(
                    id: sofiaID,
                    fullName: "Sofia Ducrest",
                    email: "sofia@example.com",
                    city: "Lausanne",
                    localeIdentifier: "fr_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                malikID: UserAccount(
                    id: malikID,
                    fullName: "Malik Bensaid",
                    email: "malik@example.com",
                    city: "Bern",
                    localeIdentifier: "fr_CH",
                    roles: [.guest, .host],
                    verificationState: .hostApproved
                ),
                leilaID: UserAccount(
                    id: leilaID,
                    fullName: "Leila Schmid",
                    email: "leila@example.com",
                    city: "Zurich",
                    localeIdentifier: "de_CH",
                    roles: [.guest],
                    verificationState: .emailVerified
                ),
                tobiasID: UserAccount(
                    id: tobiasID,
                    fullName: "Tobias Frei",
                    email: "tobias@example.com",
                    city: "Basel",
                    localeIdentifier: "de_CH",
                    roles: [.guest],
                    verificationState: .emailVerified
                ),
                noraID: UserAccount(
                    id: noraID,
                    fullName: "Nora Chevalier",
                    email: "nora@example.com",
                    city: "Geneva",
                    localeIdentifier: "fr_CH",
                    roles: [.guest],
                    verificationState: .emailVerified
                )
            ]

            let guestProfiles: [UUID: GuestProfile] = [
                currentUserID: GuestProfile(
                    userID: currentUserID,
                    displayName: "Aarav",
                    bio: "I travel through cities by meeting people at the table first.",
                    dietaryPreferences: ["Vegetarian-friendly", "No shellfish"],
                    spokenLanguages: ["English", "Hindi", "German"]
                ),
                elenaID: GuestProfile(
                    userID: elenaID,
                    displayName: "Elena",
                    bio: "Always curious about regional dishes and migration stories.",
                    dietaryPreferences: ["Pescatarian"],
                    spokenLanguages: ["Italian", "English"]
                ),
                kenjiID: GuestProfile(
                    userID: kenjiID,
                    displayName: "Kenji",
                    bio: "I enjoy small dinners where people actually talk.",
                    dietaryPreferences: ["No dairy"],
                    spokenLanguages: ["Japanese", "English"]
                ),
                julesID: GuestProfile(
                    userID: julesID,
                    displayName: "Jules",
                    bio: "A local guest who likes long Sunday lunches.",
                    dietaryPreferences: ["No restrictions"],
                    spokenLanguages: ["French", "English"]
                ),
                amiraID: GuestProfile(
                    userID: amiraID,
                    displayName: "Amira",
                    bio: "I host tables that feel like a living room before they feel like an event.",
                    dietaryPreferences: ["Halal-friendly"],
                    spokenLanguages: ["Arabic", "French", "English"]
                ),
                sofiaID: GuestProfile(
                    userID: sofiaID,
                    displayName: "Sofia",
                    bio: "I love seasonal menus and guests who ask about the region behind the ingredients.",
                    dietaryPreferences: ["Vegetarian-friendly"],
                    spokenLanguages: ["French", "English"]
                ),
                malikID: GuestProfile(
                    userID: malikID,
                    displayName: "Malik",
                    bio: "Meals should feel generous, not formal.",
                    dietaryPreferences: ["No pork"],
                    spokenLanguages: ["Arabic", "French", "German"]
                ),
                leilaID: GuestProfile(
                    userID: leilaID,
                    displayName: "Leila",
                    bio: "I book meals when I want a city to feel human quickly.",
                    dietaryPreferences: ["Nut-aware"],
                    spokenLanguages: ["German", "English"]
                ),
                tobiasID: GuestProfile(
                    userID: tobiasID,
                    displayName: "Tobias",
                    bio: "Looking for small tables, not noisy events.",
                    dietaryPreferences: ["No alcohol"],
                    spokenLanguages: ["German", "English"]
                ),
                noraID: GuestProfile(
                    userID: noraID,
                    displayName: "Nora",
                    bio: "I travel between Geneva and Zurich and like meeting hosts through food.",
                    dietaryPreferences: ["Vegetarian"],
                    spokenLanguages: ["French", "English"]
                )
            ]

            let hostProfiles: [UUID: HostProfile] = [
                currentUserID: HostProfile(
                    userID: currentUserID,
                    approvalStatus: .approved,
                    homeCity: "Zurich",
                    neighborhood: "Wiedikon",
                    spokenLanguages: ["English", "Hindi", "German"],
                    cultureStory: "Modern Indian comfort food with stories about migration, spice memory, and regional rituals from Kerala to Mumbai.",
                    houseRules: "Shoes off at the door. Come hungry and curious.",
                    safetyNotes: "Nut-free menu on request and elevator access available."
                ),
                elenaID: HostProfile(
                    userID: elenaID,
                    approvalStatus: .approved,
                    homeCity: "Zurich",
                    neighborhood: "Seefeld",
                    spokenLanguages: ["Italian", "English", "German"],
                    cultureStory: "Slow Roman dinner with family recipes and how food changed after moving to Switzerland.",
                    houseRules: "Please arrive within 10 minutes of the start time.",
                    safetyNotes: "Vegetarian menu available with advance notice."
                ),
                kenjiID: HostProfile(
                    userID: kenjiID,
                    approvalStatus: .approved,
                    homeCity: "Basel",
                    neighborhood: "St. Johann",
                    spokenLanguages: ["Japanese", "English"],
                    cultureStory: "A quiet Japanese lunch built around seasonal home cooking and tea.",
                    houseRules: "Small bags only because seating is compact.",
                    safetyNotes: "Two friendly cats live in the apartment."
                ),
                amiraID: HostProfile(
                    userID: amiraID,
                    approvalStatus: .approved,
                    homeCity: "Geneva",
                    neighborhood: "Eaux-Vives",
                    spokenLanguages: ["Arabic", "French", "English"],
                    cultureStory: "Levantine dinners built around shared plates, migration stories, and dishes that carry memory across cities.",
                    houseRules: "Please mention allergies before arriving. Shared table format.",
                    safetyNotes: "Lift access available and alcohol-free pairing offered."
                ),
                sofiaID: HostProfile(
                    userID: sofiaID,
                    approvalStatus: .approved,
                    homeCity: "Lausanne",
                    neighborhood: "Sous-Gare",
                    spokenLanguages: ["French", "English"],
                    cultureStory: "A Vaud table focused on lake fish, market produce, and stories about local growers.",
                    houseRules: "Arrive on time because the menu is served in sequence.",
                    safetyNotes: "One small dog lives in the apartment."
                ),
                malikID: HostProfile(
                    userID: malikID,
                    approvalStatus: .approved,
                    homeCity: "Bern",
                    neighborhood: "Breitenrain",
                    spokenLanguages: ["Arabic", "French", "German"],
                    cultureStory: "North African home cooking with slow stews, couscous rituals, and stories from family gatherings.",
                    houseRules: "Respect quiet hours in the building after 22:00.",
                    safetyNotes: "Gluten-free couscous can be prepared with notice."
                )
            ]

            let aaravExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "D3600945-6C2F-4B2E-BE89-CF5049E337AF") ?? UUID(),
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                title: "Kerala Lunch With Spice Stories",
                mealTypeRawValue: "lunch",
                vibeRawValue: "familyStyle",
                cuisineOrigin: "South Indian",
                description: "A long-table lunch with appam, stew, and stories about how family menus travel between generations and cities.",
                city: "Zurich",
                neighborhood: "Wiedikon",
                fullAddress: "Birmensdorferstrasse 188, 8003 Zurich",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 4,
                dietarySupportCSV: "Vegetarian-friendly, Mild spice option",
                spokenLanguagesCSV: "English, Hindi, German",
                publishStateRawValue: "published",
                availableFrom: day(after: 5),
                availableUntil: day(after: 10),
                serviceHour: 12,
                serviceMinute: 30,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 7)])
            )

            let elenaExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "F662F76E-0EE3-4CF9-B0DA-7C9244382A38") ?? UUID(),
                hostID: elenaID,
                hostName: users[elenaID]?.fullName ?? "Elena Rossi",
                title: "Roman Dinner Around Family Recipes",
                mealTypeRawValue: "dinner",
                vibeRawValue: "storytelling",
                cuisineOrigin: "Roman Italian",
                description: "A candlelit dinner about Sunday sauces, migration, and how recipes survive in small apartments.",
                city: "Zurich",
                neighborhood: "Seefeld",
                fullAddress: "Seefeldstrasse 71, 8008 Zurich",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 6,
                dietarySupportCSV: "Vegetarian menu, Gluten-aware starter",
                spokenLanguagesCSV: "Italian, English, German",
                publishStateRawValue: "published",
                availableFrom: day(after: 2),
                availableUntil: day(after: 7),
                serviceHour: 19,
                serviceMinute: 0,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 5)])
            )

            let kenjiExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "56DBD589-CA22-4E01-B4A4-84E502E90541") ?? UUID(),
                hostID: kenjiID,
                hostName: users[kenjiID]?.fullName ?? "Kenji Sato",
                title: "Seasonal Bento Lunch and Tea",
                mealTypeRawValue: "lunch",
                vibeRawValue: "chefTable",
                cuisineOrigin: "Japanese Home Cooking",
                description: "A quiet lunch with tea service and small stories about everyday Japanese meals that never make restaurant menus.",
                city: "Basel",
                neighborhood: "St. Johann",
                fullAddress: "Elsasserstrasse 153, 4056 Basel",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 4,
                dietarySupportCSV: "Dairy-free, Alcohol-free",
                spokenLanguagesCSV: "Japanese, English",
                publishStateRawValue: "published",
                availableFrom: day(after: 4),
                availableUntil: day(after: 8),
                serviceHour: 12,
                serviceMinute: 0,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 6)])
            )

            let aaravDinnerRecord = ExperienceRecord(
                id: UUID(uuidString: "BC1F4B0E-47EA-4E1E-9BE3-78F6D0482347") ?? UUID(),
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                title: "Bombay Supper Club At Home",
                mealTypeRawValue: "dinner",
                vibeRawValue: "festive",
                cuisineOrigin: "Bombay Home Cooking",
                description: "A louder, more social dinner with chaat, curry, and stories about cosmopolitan home kitchens.",
                city: "Zurich",
                neighborhood: "Wiedikon",
                fullAddress: "Birmensdorferstrasse 188, 8003 Zurich",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 5,
                dietarySupportCSV: "Vegetarian menu, Mild spice option",
                spokenLanguagesCSV: "English, Hindi, German",
                publishStateRawValue: "published",
                availableFrom: day(after: 8),
                availableUntil: day(after: 12),
                serviceHour: 19,
                serviceMinute: 30,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 10)])
            )

            let amiraExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "CE4D63CE-4ED8-4D7D-A25A-C8A98A6B3098") ?? UUID(),
                hostID: amiraID,
                hostName: users[amiraID]?.fullName ?? "Amira Haddad",
                title: "Levantine Friday Supper",
                mealTypeRawValue: "dinner",
                vibeRawValue: "familyStyle",
                cuisineOrigin: "Levantine",
                description: "Shared mezze, mains, and migration stories from Beirut to Geneva at one long table.",
                city: "Geneva",
                neighborhood: "Eaux-Vives",
                fullAddress: "Rue des Vollandes 32, 1207 Geneva",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 6,
                dietarySupportCSV: "Halal-friendly, Vegetarian menu",
                spokenLanguagesCSV: "Arabic, French, English",
                publishStateRawValue: "published",
                availableFrom: day(after: 6),
                availableUntil: day(after: 11),
                serviceHour: 19,
                serviceMinute: 15,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 9)])
            )

            let sofiaExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "463F4D13-684F-4EE2-9A2F-BE95E9349D32") ?? UUID(),
                hostID: sofiaID,
                hostName: users[sofiaID]?.fullName ?? "Sofia Ducrest",
                title: "Lakeview Vaud Brunch",
                mealTypeRawValue: "lunch",
                vibeRawValue: "storytelling",
                cuisineOrigin: "Swiss Romand",
                description: "A relaxed brunch with local cheeses, orchard dishes, and stories about the Vaud region.",
                city: "Lausanne",
                neighborhood: "Sous-Gare",
                fullAddress: "Avenue Louis-Ruchonnet 18, 1003 Lausanne",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 5,
                dietarySupportCSV: "Vegetarian-friendly, Non-alcoholic pairings",
                spokenLanguagesCSV: "French, English",
                publishStateRawValue: "published",
                availableFrom: day(after: 7),
                availableUntil: day(after: 11),
                serviceHour: 11,
                serviceMinute: 30,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 10)])
            )

            let malikExperienceRecord = ExperienceRecord(
                id: UUID(uuidString: "0B4A9F17-F9E7-45B6-B721-85D1E0AE9179") ?? UUID(),
                hostID: malikID,
                hostName: users[malikID]?.fullName ?? "Malik Bensaid",
                title: "Couscous Night In Bern",
                mealTypeRawValue: "dinner",
                vibeRawValue: "chefTable",
                cuisineOrigin: "North African Home Cooking",
                description: "A generous couscous dinner and tea service with stories about family gatherings and hospitality rituals.",
                city: "Bern",
                neighborhood: "Breitenrain",
                fullAddress: "Moserstrasse 41, 3014 Bern",
                addressPrivacyRawValue: "neighborhoodOnly",
                maxSeats: 6,
                dietarySupportCSV: "No pork, Gluten-free option",
                spokenLanguagesCSV: "Arabic, French, German",
                publishStateRawValue: "published",
                availableFrom: day(after: 9),
                availableUntil: day(after: 13),
                serviceHour: 19,
                serviceMinute: 0,
                blockedDayKeysCSV: encodeDayKeyCSV([dayKey(after: 12)])
            )

            let experiencesArray = [
                MarketplaceMapper.makeExperience(from: aaravExperienceRecord),
                MarketplaceMapper.makeExperience(from: elenaExperienceRecord),
                MarketplaceMapper.makeExperience(from: kenjiExperienceRecord),
                MarketplaceMapper.makeExperience(from: aaravDinnerRecord),
                MarketplaceMapper.makeExperience(from: amiraExperienceRecord),
                MarketplaceMapper.makeExperience(from: sofiaExperienceRecord),
                MarketplaceMapper.makeExperience(from: malikExperienceRecord)
            ]

            let experiences = Dictionary(uniqueKeysWithValues: experiencesArray.map { ($0.id, $0) })

            func slot(for experienceID: UUID, dayOffset: Int) -> ExperienceSlot {
                guard let experience = experiences[experienceID],
                      let slot = experience.slot(on: dayKey(after: dayOffset)) else {
                    fatalError("Missing seeded slot for experience \(experienceID) on offset \(dayOffset)")
                }

                return slot
            }

            let elenaPendingSlot = slot(for: elenaExperienceRecord.id, dayOffset: 2)
            let kenjiAcceptedSlot = slot(for: kenjiExperienceRecord.id, dayOffset: 4)
            let aaravHostSlot = slot(for: aaravExperienceRecord.id, dayOffset: 5)
            let aaravDinnerHostSlot = slot(for: aaravDinnerRecord.id, dayOffset: 8)
            let sofiaPendingSlot = slot(for: sofiaExperienceRecord.id, dayOffset: 7)
            let amiraDeclinedSlot = slot(for: amiraExperienceRecord.id, dayOffset: 6)

            let guestPendingRequest = BookingRequest(
                id: UUID(uuidString: "6682F57A-720D-4A0D-A80A-52B4E521AE76") ?? UUID(),
                experienceID: elenaExperienceRecord.id,
                experienceTitle: "Roman Dinner Around Family Recipes",
                hostID: elenaID,
                hostName: users[elenaID]?.fullName ?? "Elena Rossi",
                guestID: currentUserID,
                guestName: users[currentUserID]?.fullName ?? "Aarav Menon",
                slotID: elenaPendingSlot.id,
                slotStartAt: elenaPendingSlot.startAt,
                seatsRequested: 2,
                introMessage: "I’d love to bring a friend who collects family recipes.",
                guestNotes: "Vegetarian option for one seat, please.",
                status: .pending
            )

            let guestAcceptedRequest = BookingRequest(
                id: UUID(uuidString: "1D0D546A-5AA5-4D7F-8A16-58BD5730A836") ?? UUID(),
                experienceID: kenjiExperienceRecord.id,
                experienceTitle: "Seasonal Bento Lunch and Tea",
                hostID: kenjiID,
                hostName: users[kenjiID]?.fullName ?? "Kenji Sato",
                guestID: currentUserID,
                guestName: users[currentUserID]?.fullName ?? "Aarav Menon",
                slotID: kenjiAcceptedSlot.id,
                slotStartAt: kenjiAcceptedSlot.startAt,
                seatsRequested: 1,
                introMessage: "I’m curious about everyday dishes rather than restaurant classics.",
                guestNotes: "No dairy, please.",
                status: .accepted
            )

            let hostPendingRequest = BookingRequest(
                id: UUID(uuidString: "8849E9A9-5627-4987-B9E8-FD92030E4D85") ?? UUID(),
                experienceID: aaravExperienceRecord.id,
                experienceTitle: "Kerala Lunch With Spice Stories",
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                guestID: julesID,
                guestName: users[julesID]?.fullName ?? "Jules Martin",
                slotID: aaravHostSlot.id,
                slotStartAt: aaravHostSlot.startAt,
                seatsRequested: 2,
                introMessage: "I’m local but want to discover the story behind the menu.",
                guestNotes: "One guest is mildly spice-sensitive.",
                status: .pending
            )

            let guestSecondPendingRequest = BookingRequest(
                id: UUID(uuidString: "CD975A3F-85F5-409A-9B7B-F67882A2D112") ?? UUID(),
                experienceID: sofiaExperienceRecord.id,
                experienceTitle: "Lakeview Vaud Brunch",
                hostID: sofiaID,
                hostName: users[sofiaID]?.fullName ?? "Sofia Ducrest",
                guestID: currentUserID,
                guestName: users[currentUserID]?.fullName ?? "Aarav Menon",
                slotID: sofiaPendingSlot.id,
                slotStartAt: sofiaPendingSlot.startAt,
                seatsRequested: 2,
                introMessage: "I’m planning a weekend in Lausanne and want something local rather than touristy.",
                guestNotes: "Vegetarian-friendly if possible.",
                status: .pending
            )

            let guestDeclinedRequest = BookingRequest(
                id: UUID(uuidString: "619D21E2-C0A7-4639-9BDE-D0C4109D0F30") ?? UUID(),
                experienceID: amiraExperienceRecord.id,
                experienceTitle: "Levantine Friday Supper",
                hostID: amiraID,
                hostName: users[amiraID]?.fullName ?? "Amira Haddad",
                guestID: currentUserID,
                guestName: users[currentUserID]?.fullName ?? "Aarav Menon",
                slotID: amiraDeclinedSlot.id,
                slotStartAt: amiraDeclinedSlot.startAt,
                seatsRequested: 1,
                introMessage: "I’ll be in Geneva for one night and would love a shared table.",
                guestNotes: "",
                status: .declined
            )

            let hostAcceptedRequest = BookingRequest(
                id: UUID(uuidString: "DDA6A5A1-6669-4D2C-9890-C1FE2A6896F4") ?? UUID(),
                experienceID: aaravExperienceRecord.id,
                experienceTitle: "Kerala Lunch With Spice Stories",
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                guestID: leilaID,
                guestName: users[leilaID]?.fullName ?? "Leila Schmid",
                slotID: aaravHostSlot.id,
                slotStartAt: aaravHostSlot.startAt,
                seatsRequested: 1,
                introMessage: "I want to understand the story behind the menu, not just the food.",
                guestNotes: "Nut-aware, please.",
                status: .accepted
            )

            let secondHostPendingRequest = BookingRequest(
                id: UUID(uuidString: "F408513E-D5E8-40E9-81C9-48E8D4517A0C") ?? UUID(),
                experienceID: aaravDinnerRecord.id,
                experienceTitle: "Bombay Supper Club At Home",
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                guestID: tobiasID,
                guestName: users[tobiasID]?.fullName ?? "Tobias Frei",
                slotID: aaravDinnerHostSlot.id,
                slotStartAt: aaravDinnerHostSlot.startAt,
                seatsRequested: 2,
                introMessage: "I’m looking for a more social dinner, but still in a home setting.",
                guestNotes: "No alcohol, please.",
                status: .pending
            )

            let hostFullDateRequest = BookingRequest(
                id: UUID(uuidString: "4DAE6F51-C8F9-4BF4-9001-4053191C9189") ?? UUID(),
                experienceID: aaravExperienceRecord.id,
                experienceTitle: "Kerala Lunch With Spice Stories",
                hostID: currentUserID,
                hostName: users[currentUserID]?.fullName ?? "Aarav Menon",
                guestID: noraID,
                guestName: users[noraID]?.fullName ?? "Nora Chevalier",
                slotID: aaravHostSlot.id,
                slotStartAt: aaravHostSlot.startAt,
                seatsRequested: 1,
                introMessage: "I’d love a smaller lunch table while I’m in Zurich.",
                guestNotes: "Vegetarian, please.",
                status: .accepted
            )

            let sofiaFullDateRequest = BookingRequest(
                id: UUID(uuidString: "A78D46BC-0476-4F57-97D4-17AA2D3F63B3") ?? UUID(),
                experienceID: sofiaExperienceRecord.id,
                experienceTitle: "Lakeview Vaud Brunch",
                hostID: sofiaID,
                hostName: users[sofiaID]?.fullName ?? "Sofia Ducrest",
                guestID: noraID,
                guestName: users[noraID]?.fullName ?? "Nora Chevalier",
                slotID: sofiaPendingSlot.id,
                slotStartAt: sofiaPendingSlot.startAt,
                seatsRequested: 3,
                introMessage: "I’m traveling through Lausanne and want a local brunch conversation.",
                guestNotes: "",
                status: .accepted
            )

            let bookingRequests = [
                guestPendingRequest,
                guestAcceptedRequest,
                hostPendingRequest,
                guestSecondPendingRequest,
                guestDeclinedRequest,
                hostAcceptedRequest,
                secondHostPendingRequest,
                hostFullDateRequest,
                sofiaFullDateRequest
            ]

            let moderationRecords: [UUID: [AdminReviewRecord]] = [
                currentUserID: [
                    AdminReviewRecord(
                        id: UUID(),
                        hostUserID: currentUserID,
                        reviewerName: "Ops Team",
                        status: .approved,
                        note: "Approved for public hosting after profile review and cultural story check.",
                        reviewedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
                    )
                ],
                amiraID: [
                    AdminReviewRecord(
                        id: UUID(),
                        hostUserID: amiraID,
                        reviewerName: "Ops Team",
                        status: .approved,
                        note: "Approved after reviewing home rules, allergy handling, and cultural story quality.",
                        reviewedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now
                    )
                ],
                sofiaID: [
                    AdminReviewRecord(
                        id: UUID(),
                        hostUserID: sofiaID,
                        reviewerName: "Ops Team",
                        status: .approved,
                        note: "Approved for small-format brunch hosting with local storytelling focus.",
                        reviewedAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now
                    )
                ]
            ]

            return SeedData(
                currentUserID: currentUserID,
                users: users,
                guestProfiles: guestProfiles,
                hostProfiles: hostProfiles,
                experiences: experiences,
                bookingRequests: Dictionary(uniqueKeysWithValues: bookingRequests.map { ($0.id, $0) }),
                moderationRecords: moderationRecords
            )
        }
    }
}

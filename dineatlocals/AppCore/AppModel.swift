import Observation
import SwiftData
import SwiftUI

enum MarketplaceTab: String, CaseIterable, Identifiable, Hashable {
    case discover
    case requests
    case host
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover:
            "Discover"
        case .requests:
            "Requests"
        case .host:
            "Host"
        case .profile:
            "Profile"
        }
    }

    var systemImageName: String {
        switch self {
        case .discover:
            "sparkles.rectangle.stack"
        case .requests:
            "tray.full"
        case .host:
            "house.lodge"
        case .profile:
            "person.crop.circle"
        }
    }
}

@MainActor
@Observable
final class AppModel {
    var activeTab: MarketplaceTab = .discover
    var isLoading = false
    var hasLoaded = false
    var errorMessage: String?
    var noticeMessage: String?

    var currentUser: UserAccount?
    var guestProfile: GuestProfile?
    var hostProfile: HostProfile?
    var moderationRecords: [AdminReviewRecord] = []

    var discoverFilter = ExperienceFilter()
    var availableCities: [String] = []
    var experiences: [Experience] = []
    var hostExperiences: [Experience] = []
    var guestRequests: [BookingRequest] = []
    var hostRequests: [BookingRequest] = []

    private let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    static func preview() -> AppModel {
        AppModel(services: .mock())
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refreshAll()
        hasLoaded = true
    }

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await services.authService.currentUser()
            let guestProfile = try await services.profileService.fetchGuestProfile(userID: user.id)
            let hostProfile = try await services.profileService.fetchHostProfile(userID: user.id)
            let moderationRecords = try await services.moderationService.fetchHostReviews(hostID: user.id)
            let cities = try await services.experienceService.catalogCities()

            currentUser = user
            self.guestProfile = guestProfile
            self.hostProfile = hostProfile
            self.moderationRecords = moderationRecords
            availableCities = cities

            await reloadDiscover()
            await reloadRequests()
            await reloadHostExperiences()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadDiscover() async {
        do {
            experiences = try await services.experienceService.discoverExperiences(filter: discoverFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadRequests() async {
        guard let currentUser else { return }

        do {
            guestRequests = try await services.bookingService.guestRequests(userID: currentUser.id)
            hostRequests = try await services.bookingService.hostRequests(hostID: currentUser.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadHostExperiences() async {
        guard let currentUser else { return }

        do {
            hostExperiences = try await services.experienceService.hostExperiences(hostID: currentUser.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveGuestProfile(bio: String, dietaryPreferences: [String], spokenLanguages: [String]) async {
        guard var guestProfile else { return }
        errorMessage = nil

        guestProfile.bio = bio
        guestProfile.dietaryPreferences = dietaryPreferences
        guestProfile.spokenLanguages = spokenLanguages

        do {
            self.guestProfile = try await services.profileService.updateGuestProfile(guestProfile)
            showNotice("Guest profile updated.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitHostApplication(draft: HostApplicationDraft) async {
        guard let currentUser else { return }
        errorMessage = nil

        let profile = HostProfile(
            userID: currentUser.id,
            approvalStatus: .pendingReview,
            homeCity: draft.homeCity,
            neighborhood: draft.neighborhood,
            spokenLanguages: draft.spokenLanguages,
            cultureStory: draft.cultureStory,
            houseRules: draft.houseRules,
            safetyNotes: draft.safetyNotes
        )

        do {
            hostProfile = try await services.profileService.submitHostProfile(profile)
            moderationRecords = try await services.moderationService.fetchHostReviews(hostID: currentUser.id)
            showNotice("Host profile submitted for review.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createExperience(draft: ExperienceDraft) async {
        guard let currentUser else { return }
        errorMessage = nil

        do {
            _ = try await services.experienceService.createExperience(draft: draft, hostID: currentUser.id)
            await reloadHostExperiences()
            await reloadDiscover()
            showNotice("Experience published.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePublish(for experience: Experience) async {
        guard let currentUser else { return }
        errorMessage = nil

        let nextState: ExperiencePublishState = experience.publishState == .published ? .paused : .published

        do {
            _ = try await services.experienceService.setPublishState(nextState, for: experience.id, hostID: currentUser.id)
            await reloadHostExperiences()
            await reloadDiscover()
            showNotice(nextState == .published ? "Experience reopened." : "Experience paused.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateBlockedDays(for experience: Experience, blockedDays: Set<DayKey>) async {
        guard let currentUser else { return }
        errorMessage = nil

        do {
            _ = try await services.experienceService.updateBlockedDays(blockedDays, for: experience.id, hostID: currentUser.id)
            await reloadHostExperiences()
            await reloadDiscover()
            showNotice("Availability updated.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitBookingRequest(
        experience: Experience,
        slotID: UUID,
        seatsRequested: Int,
        introMessage: String,
        guestNotes: String
    ) async {
        guard let currentUser else { return }
        errorMessage = nil

        let draft = BookingRequestDraft(
            experienceID: experience.id,
            slotID: slotID,
            seatsRequested: seatsRequested,
            introMessage: introMessage,
            guestNotes: guestNotes
        )

        do {
            _ = try await services.bookingService.submitRequest(draft: draft, guestID: currentUser.id)
            await reloadRequests()
            await reloadDiscover()
            activeTab = .requests
            showNotice("Booking request sent.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateRequestStatus(_ status: RequestStatus, request: BookingRequest) async {
        guard let currentUser else { return }
        errorMessage = nil

        do {
            _ = try await services.bookingService.updateRequestStatus(status, requestID: request.id, actorID: currentUser.id)
            await reloadRequests()
            await reloadDiscover()
            showNotice("Request marked \(status.title.lowercased()).")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func visibleAddress(for experience: Experience) -> String {
        guard let currentUser else {
            return "\(experience.neighborhood), \(experience.city)"
        }

        if experience.hostID == currentUser.id || experience.addressPrivacy == .publicListing {
            return experience.fullAddress
        }

        let canReveal = guestRequests.contains {
            $0.experienceID == experience.id && $0.status == .accepted && $0.guestID == currentUser.id
        }

        return canReveal ? experience.fullAddress : "\(experience.neighborhood), \(experience.city)"
    }

    func canCurrentUserRequest(_ experience: Experience) -> Bool {
        currentUser?.id != experience.hostID
    }

    func heroSymbol(for experience: Experience) async -> String {
        await services.mediaService.heroSymbol(for: experience)
    }

    func galleryAssetNames(for experience: Experience) async -> [String] {
        await services.mediaService.galleryAssetNames(for: experience)
    }

    func syncDiscoveryCache(using context: ModelContext) {
        do {
            let existingRecords = try context.fetch(FetchDescriptor<CachedExperienceRecord>())
            existingRecords.forEach(context.delete)

            for experience in experiences {
                context.insert(CachedExperienceRecord(experience: experience))
            }

            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showNotice(_ message: String) {
        noticeMessage = message

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            if noticeMessage == message {
                noticeMessage = nil
            }
        }
    }
}

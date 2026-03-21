import Foundation

protocol AuthService: Sendable {
    func currentUser() async throws -> UserAccount
}

protocol ProfileService: Sendable {
    func fetchGuestProfile(userID: UUID) async throws -> GuestProfile
    func fetchHostProfile(userID: UUID) async throws -> HostProfile?
    func updateGuestProfile(_ profile: GuestProfile) async throws -> GuestProfile
    func submitHostProfile(_ profile: HostProfile) async throws -> HostProfile
}

protocol ExperienceService: Sendable {
    func catalogCities() async throws -> [String]
    func discoverExperiences(filter: ExperienceFilter) async throws -> [Experience]
    func hostExperiences(hostID: UUID) async throws -> [Experience]
    func createExperience(draft: ExperienceDraft, hostID: UUID) async throws -> Experience
    func setPublishState(_ state: ExperiencePublishState, for experienceID: UUID, hostID: UUID) async throws -> Experience
    func updateBlockedDays(_ blockedDays: Set<DayKey>, for experienceID: UUID, hostID: UUID) async throws -> Experience
}

protocol BookingService: Sendable {
    func guestRequests(userID: UUID) async throws -> [BookingRequest]
    func hostRequests(hostID: UUID) async throws -> [BookingRequest]
    func submitRequest(draft: BookingRequestDraft, guestID: UUID) async throws -> BookingRequest
    func updateRequestStatus(_ status: RequestStatus, requestID: UUID, actorID: UUID) async throws -> BookingRequest
}

protocol ModerationService: Sendable {
    func fetchHostReviews(hostID: UUID) async throws -> [AdminReviewRecord]
}

protocol MediaService: Sendable {
    func heroSymbol(for experience: Experience) async -> String
    func galleryAssetNames(for experience: Experience) async -> [String]
}

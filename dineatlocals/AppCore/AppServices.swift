struct AppServices {
    let authService: any AuthService
    let profileService: any ProfileService
    let experienceService: any ExperienceService
    let bookingService: any BookingService
    let moderationService: any ModerationService
    let mediaService: any MediaService

    static func mock() -> AppServices {
        let store = MockMarketplaceStore()
        return AppServices(
            authService: store,
            profileService: store,
            experienceService: store,
            bookingService: store,
            moderationService: store,
            mediaService: store
        )
    }
}

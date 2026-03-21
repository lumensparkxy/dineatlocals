import Foundation

enum AppRole: String, CaseIterable, Codable, Sendable {
    case guest
    case host
}

enum VerificationState: String, Codable, Sendable {
    case emailVerified
    case pendingIdentity
    case hostApproved

    var title: String {
        switch self {
        case .emailVerified:
            "Email Verified"
        case .pendingIdentity:
            "Identity Pending"
        case .hostApproved:
            "Host Approved"
        }
    }
}

enum HostApprovalStatus: String, Codable, Sendable {
    case notApplied
    case pendingReview
    case approved
    case paused

    var title: String {
        switch self {
        case .notApplied:
            "Not Applied"
        case .pendingReview:
            "Pending Review"
        case .approved:
            "Approved"
        case .paused:
            "Paused"
        }
    }
}

enum ExperienceMealType: String, CaseIterable, Codable, Identifiable, Sendable {
    case lunch
    case dinner

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var symbolName: String {
        switch self {
        case .lunch:
            "sun.max.fill"
        case .dinner:
            "moon.stars.fill"
        }
    }
}

enum ExperienceVibe: String, CaseIterable, Codable, Identifiable, Sendable {
    case familyStyle
    case storytelling
    case chefTable
    case festive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .familyStyle:
            "Family Style"
        case .storytelling:
            "Storytelling"
        case .chefTable:
            "Chef Table"
        case .festive:
            "Festive Table"
        }
    }
}

enum AddressPrivacy: String, Codable, Sendable {
    case neighborhoodOnly
    case publicListing
}

enum ExperiencePublishState: String, Codable, Sendable {
    case draft
    case published
    case paused

    var title: String {
        rawValue.capitalized
    }
}

enum RequestStatus: String, CaseIterable, Codable, Sendable {
    case pending
    case accepted
    case declined
    case cancelled
    case completed

    var title: String {
        rawValue.capitalized
    }
}

struct UserAccount: Identifiable, Equatable, Sendable {
    let id: UUID
    var fullName: String
    var email: String
    var city: String
    var localeIdentifier: String
    var roles: [AppRole]
    var verificationState: VerificationState
}

struct GuestProfile: Equatable, Sendable {
    var userID: UUID
    var displayName: String
    var bio: String
    var dietaryPreferences: [String]
    var spokenLanguages: [String]
}

struct HostProfile: Equatable, Sendable {
    var userID: UUID
    var approvalStatus: HostApprovalStatus
    var homeCity: String
    var neighborhood: String
    var spokenLanguages: [String]
    var cultureStory: String
    var houseRules: String
    var safetyNotes: String
}

struct ExperienceSlot: Identifiable, Equatable, Sendable {
    var id: UUID
    var startAt: Date
    var seatCapacity: Int
    var manualAvailability: ExperienceSlotAvailability
    var activeSeats: Int

    nonisolated var dayKey: DayKey {
        DayKey(date: startAt)
    }

    nonisolated var remainingSeats: Int {
        max(seatCapacity - activeSeats, 0)
    }

    nonisolated var isFull: Bool {
        remainingSeats == 0
    }

    nonisolated var hasActiveRequests: Bool {
        activeSeats > 0
    }

    nonisolated var isBookable: Bool {
        manualAvailability == .available && !isFull && startAt >= .now
    }
}

struct Experience: Identifiable, Equatable, Sendable {
    var id: UUID
    var hostID: UUID
    var hostName: String
    var title: String
    var mealType: ExperienceMealType
    var vibe: ExperienceVibe
    var cuisineOrigin: String
    var description: String
    var city: String
    var neighborhood: String
    var fullAddress: String
    var addressPrivacy: AddressPrivacy
    var maxSeats: Int
    var dietarySupport: [String]
    var spokenLanguages: [String]
    var photoAssetNames: [String] = []
    var publishState: ExperiencePublishState
    var slots: [ExperienceSlot]

    nonisolated var bookableSlots: [ExperienceSlot] {
        guard publishState == .published else { return [] }

        return slots
            .filter(\.isBookable)
            .sorted { $0.startAt < $1.startAt }
    }

    nonisolated var nextStartAt: Date? {
        bookableSlots.first?.startAt
    }

    nonisolated var scheduleRange: ClosedRange<DayKey>? {
        guard let firstDay = slots.map(\.dayKey).min(),
              let lastDay = slots.map(\.dayKey).max() else {
            return nil
        }

        return firstDay...lastDay
    }

    nonisolated var blockedDays: Set<DayKey> {
        Set(slots.filter { $0.manualAvailability == .blockedByHost }.map(\.dayKey))
    }

    nonisolated var serviceTime: Date? {
        slots.sorted { $0.startAt < $1.startAt }.first?.startAt
    }

    nonisolated func slot(on dayKey: DayKey) -> ExperienceSlot? {
        slots.first { $0.dayKey == dayKey }
    }
}

struct BookingRequest: Identifiable, Equatable, Sendable {
    var id: UUID
    var experienceID: UUID
    var experienceTitle: String
    var hostID: UUID
    var hostName: String
    var guestID: UUID
    var guestName: String
    var slotID: UUID
    var slotStartAt: Date
    var seatsRequested: Int
    var introMessage: String
    var guestNotes: String
    var status: RequestStatus
}

struct Review: Identifiable, Equatable, Sendable {
    var id: UUID
    var bookingRequestID: UUID
    var authorUserID: UUID
    var rating: Int
    var text: String
}

struct AdminReviewRecord: Identifiable, Equatable, Sendable {
    var id: UUID
    var hostUserID: UUID
    var reviewerName: String
    var status: HostApprovalStatus
    var note: String
    var reviewedAt: Date
}

struct ExperienceFilter: Equatable, Sendable {
    var searchText: String = ""
    var city: String?
    var mealType: ExperienceMealType?
    var vibe: ExperienceVibe?
}

struct ExperienceDraft: Equatable, Sendable {
    var title: String = ""
    var mealType: ExperienceMealType = .dinner
    var vibe: ExperienceVibe = .storytelling
    var cuisineOrigin: String = ""
    var description: String = ""
    var city: String = ""
    var neighborhood: String = ""
    var fullAddress: String = ""
    var addressPrivacy: AddressPrivacy = .neighborhoodOnly
    var maxSeats: Int = 4
    var dietarySupport: [String] = []
    var spokenLanguages: [String] = []
    var availableFrom: Date = defaultExperienceRangeStart()
    var availableUntil: Date = defaultExperienceRangeEnd()
    var serviceTime: Date = defaultExperienceServiceTime()
    var blockedDays: Set<DayKey> = []
}

struct BookingRequestDraft: Equatable, Sendable {
    var experienceID: UUID
    var slotID: UUID
    var seatsRequested: Int
    var introMessage: String
    var guestNotes: String
}

struct HostApplicationDraft: Equatable, Sendable {
    var homeCity: String = ""
    var neighborhood: String = ""
    var spokenLanguages: [String] = []
    var cultureStory: String = ""
    var houseRules: String = ""
    var safetyNotes: String = ""
}

extension Array where Element == String {
    var joinedForDisplay: String {
        isEmpty ? "Not set yet" : joined(separator: ", ")
    }
}

nonisolated func parseCSVList(_ value: String) -> [String] {
    value
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

nonisolated func defaultExperienceRangeStart(calendar: Calendar = marketplaceCalendar) -> Date {
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now.addingTimeInterval(86_400)
    return calendar.startOfDay(for: tomorrow)
}

nonisolated func defaultExperienceRangeEnd(calendar: Calendar = marketplaceCalendar) -> Date {
    calendar.date(byAdding: .day, value: 6, to: defaultExperienceRangeStart(calendar: calendar))
    ?? defaultExperienceRangeStart(calendar: calendar)
}

nonisolated func defaultExperienceServiceTime(calendar: Calendar = marketplaceCalendar) -> Date {
    let today = calendar.startOfDay(for: .now)
    return calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) ?? .now
}

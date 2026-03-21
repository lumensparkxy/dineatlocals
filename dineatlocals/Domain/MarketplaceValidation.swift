import Foundation

enum MarketplaceError: LocalizedError, Equatable {
    case hostNotApproved
    case missingHostProfile
    case invalidSeats
    case capacityExceeded
    case experienceUnavailable
    case missingSlot
    case hostCannotBookOwnExperience
    case invalidRequestTransition
    case requestNotFound
    case unauthorizedAction
    case busyDateCannotBeBlocked
    case invalidDraft(String)

    var errorDescription: String? {
        switch self {
        case .hostNotApproved:
            "Hosts need manual approval before publishing experiences."
        case .missingHostProfile:
            "Create a host profile before listing a meal."
        case .invalidSeats:
            "The requested number of seats is invalid."
        case .capacityExceeded:
            "That slot no longer has enough seats available."
        case .experienceUnavailable:
            "This experience is not currently accepting requests."
        case .missingSlot:
            "Choose a valid time slot first."
        case .hostCannotBookOwnExperience:
            "Hosts cannot book their own experience."
        case .invalidRequestTransition:
            "That request action is not allowed from the current status."
        case .requestNotFound:
            "The booking request could not be found."
        case .unauthorizedAction:
            "You do not have permission to perform that action."
        case .busyDateCannotBeBlocked:
            "Dates with active guest requests cannot be blocked."
        case .invalidDraft(let reason):
            reason
        }
    }
}

enum MarketplaceValidation {
    nonisolated static func ensureHostCanPublish(_ hostProfile: HostProfile?) throws {
        guard let hostProfile else {
            throw MarketplaceError.missingHostProfile
        }

        guard hostProfile.approvalStatus == .approved else {
            throw MarketplaceError.hostNotApproved
        }
    }

    nonisolated static func ensureValidDraft(_ draft: ExperienceDraft) throws {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MarketplaceError.invalidDraft("Give the experience a title.")
        }

        guard !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MarketplaceError.invalidDraft("Add a short description for guests.")
        }

        guard !draft.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MarketplaceError.invalidDraft("Choose the city where you host.")
        }

        guard !draft.neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MarketplaceError.invalidDraft("Add the neighborhood for guest discovery.")
        }

        guard !draft.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MarketplaceError.invalidDraft("A full address is required for approved guests.")
        }

        guard draft.maxSeats > 0 else {
            throw MarketplaceError.invalidDraft("Seat capacity must be at least one.")
        }

        let calendar = marketplaceCalendar
        let startDay = calendar.startOfDay(for: draft.availableFrom)
        let endDay = calendar.startOfDay(for: draft.availableUntil)
        let today = calendar.startOfDay(for: .now)

        guard startDay >= today else {
            throw MarketplaceError.invalidDraft("Choose a start date from today onward.")
        }

        guard endDay >= startDay else {
            throw MarketplaceError.invalidDraft("The end date needs to be on or after the start date.")
        }

        let totalDays = rangeDayCount(from: startDay, to: endDay, calendar: calendar)
        guard totalDays <= 90 else {
            throw MarketplaceError.invalidDraft("Keep the range within 90 days for now.")
        }

        let validDayKeys = Set(dayKeysBetween(startDay, endDay, calendar: calendar))
        guard draft.blockedDays.isSubset(of: validDayKeys) else {
            throw MarketplaceError.invalidDraft("Blocked dates need to stay inside the chosen range.")
        }

        guard validDayKeys.subtracting(draft.blockedDays).isEmpty == false else {
            throw MarketplaceError.invalidDraft("Leave at least one available date in the range.")
        }
    }

    nonisolated static func ensureSeatCapacity(
        requestedSeats: Int,
        slotCapacity: Int,
        activeSeats: Int
    ) throws {
        guard requestedSeats > 0 else {
            throw MarketplaceError.invalidSeats
        }

        guard activeSeats + requestedSeats <= slotCapacity else {
            throw MarketplaceError.capacityExceeded
        }
    }

    nonisolated static func ensureTransition(from currentStatus: RequestStatus, to nextStatus: RequestStatus) throws {
        let allowedTransitions: [RequestStatus: Set<RequestStatus>] = [
            .pending: [.accepted, .declined, .cancelled],
            .accepted: [.cancelled, .completed],
            .declined: [],
            .cancelled: [],
            .completed: []
        ]

        guard allowedTransitions[currentStatus, default: []].contains(nextStatus) else {
            throw MarketplaceError.invalidRequestTransition
        }
    }
}

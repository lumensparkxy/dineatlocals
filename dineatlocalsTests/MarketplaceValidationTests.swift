import Foundation
import Testing
@testable import dineatlocals

struct MarketplaceValidationTests {
    @Test
    func hostNeedsApprovalBeforePublishing() {
        let hostProfile = HostProfile(
            userID: UUID(),
            approvalStatus: .pendingReview,
            homeCity: "Zurich",
            neighborhood: "Wiedikon",
            spokenLanguages: ["English"],
            cultureStory: "Story",
            houseRules: "Rules",
            safetyNotes: "Notes"
        )

        do {
            try MarketplaceValidation.ensureHostCanPublish(hostProfile)
            Issue.record("Expected a host approval error.")
        } catch let error as MarketplaceError {
            #expect(error == .hostNotApproved)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func seatCapacityRejectsOverflow() {
        do {
            try MarketplaceValidation.ensureSeatCapacity(
                requestedSeats: 3,
                slotCapacity: 4,
                activeSeats: 2
            )
            Issue.record("Expected a capacity error.")
        } catch let error as MarketplaceError {
            #expect(error == .capacityExceeded)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func draftRejectsInvalidRangeOrder() {
        var draft = validDraft()
        draft.availableUntil = marketplaceCalendar.date(byAdding: .day, value: -1, to: draft.availableFrom) ?? draft.availableFrom

        do {
            try MarketplaceValidation.ensureValidDraft(draft)
            Issue.record("Expected invalid range validation.")
        } catch let error as MarketplaceError {
            #expect(error == .invalidDraft("The end date needs to be on or after the start date."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func draftRejectsBlockedDateOutsideRange() {
        var draft = validDraft()
        draft.blockedDays = [DayKey(date: marketplaceCalendar.date(byAdding: .day, value: 12, to: draft.availableUntil) ?? draft.availableUntil)]

        do {
            try MarketplaceValidation.ensureValidDraft(draft)
            Issue.record("Expected blocked day validation to fail.")
        } catch let error as MarketplaceError {
            #expect(error == .invalidDraft("Blocked dates need to stay inside the chosen range."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func draftRejectsAllDatesBlocked() {
        var draft = validDraft()
        draft.blockedDays = Set(dayKeysBetween(draft.availableFrom, draft.availableUntil))

        do {
            try MarketplaceValidation.ensureValidDraft(draft)
            Issue.record("Expected all-blocked draft to fail.")
        } catch let error as MarketplaceError {
            #expect(error == .invalidDraft("Leave at least one available date in the range."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func draftRejectsRangeLongerThanNinetyDays() {
        var draft = validDraft()
        draft.availableUntil = marketplaceCalendar.date(byAdding: .day, value: 94, to: draft.availableFrom) ?? draft.availableUntil

        do {
            try MarketplaceValidation.ensureValidDraft(draft)
            Issue.record("Expected long-range draft to fail.")
        } catch let error as MarketplaceError {
            #expect(error == .invalidDraft("Keep the range within 90 days for now."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func validDraft() -> ExperienceDraft {
        ExperienceDraft(
            title: "Test Table",
            mealType: .dinner,
            vibe: .storytelling,
            cuisineOrigin: "Italian",
            description: "Description",
            city: "Zurich",
            neighborhood: "Seefeld",
            fullAddress: "Street 1",
            addressPrivacy: .neighborhoodOnly,
            maxSeats: 4,
            dietarySupport: [],
            spokenLanguages: [],
            availableFrom: defaultExperienceRangeStart(),
            availableUntil: marketplaceCalendar.date(byAdding: .day, value: 4, to: defaultExperienceRangeStart()) ?? defaultExperienceRangeEnd(),
            serviceTime: defaultExperienceServiceTime(),
            blockedDays: []
        )
    }
}

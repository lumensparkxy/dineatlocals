import Foundation
import Testing
@testable import dineatlocals

struct MockMarketplaceStoreTests {
    @Test
    func hostCanAcceptPendingRequest() async throws {
        let store = MockMarketplaceStore()
        let currentUser = try await store.currentUser()
        let hostRequests = try await store.hostRequests(hostID: currentUser.id)

        guard let pendingRequest = hostRequests.first(where: { $0.status == .pending }) else {
            Issue.record("Expected a pending host request in the seeded store.")
            return
        }

        let updated = try await store.updateRequestStatus(.accepted, requestID: pendingRequest.id, actorID: currentUser.id)
        #expect(updated.status == .accepted)
    }

    @Test
    func createExperienceMaterializesOneSlotPerDay() async throws {
        let store = MockMarketplaceStore()
        let currentUser = try await store.currentUser()
        let start = defaultExperienceRangeStart()
        let blockedDay = DayKey(date: marketplaceCalendar.date(byAdding: .day, value: 1, to: start) ?? start)

        let draft = ExperienceDraft(
            title: "Test Range",
            mealType: .dinner,
            vibe: .storytelling,
            cuisineOrigin: "Italian",
            description: "A test listing",
            city: "Zurich",
            neighborhood: "Wiedikon",
            fullAddress: "Street 1",
            addressPrivacy: .neighborhoodOnly,
            maxSeats: 4,
            dietarySupport: [],
            spokenLanguages: ["English"],
            availableFrom: start,
            availableUntil: marketplaceCalendar.date(byAdding: .day, value: 3, to: start) ?? start,
            serviceTime: defaultExperienceServiceTime(),
            blockedDays: Set([blockedDay])
        )

        let experience = try await store.createExperience(draft: draft, hostID: currentUser.id)

        #expect(experience.slots.count == 4)
        #expect(experience.slot(on: blockedDay)?.manualAvailability == .blockedByHost)
    }

    @Test
    func requestSubmissionRejectsCapacityOverflow() async throws {
        let seed = MockMarketplaceStore.SeedData.mock()
        let store = MockMarketplaceStore(seed: seed)

        guard let hostExperience = seed.experiences.values.first(where: { $0.title == "Kerala Lunch With Spice Stories" }),
              let fullSlot = hostExperience.slots.first(where: { $0.dayKey == DayKey(date: marketplaceCalendar.date(byAdding: .day, value: 5, to: .now) ?? .now) }),
              let guestID = seed.users.values.first(where: { $0.id != seed.currentUserID })?.id else {
            Issue.record("Seed data was missing the expected full slot or guest.")
            return
        }

        let draft = BookingRequestDraft(
            experienceID: hostExperience.id,
            slotID: fullSlot.id,
            seatsRequested: 1,
            introMessage: "We want to join.",
            guestNotes: ""
        )

        do {
            _ = try await store.submitRequest(draft: draft, guestID: guestID)
            Issue.record("Expected the request to exceed slot capacity.")
        } catch let error as MarketplaceError {
            #expect(error == .capacityExceeded)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func blockedDatesCannotBeBooked() async throws {
        let seed = MockMarketplaceStore.SeedData.mock()
        let store = MockMarketplaceStore(seed: seed)

        guard let elenaExperience = seed.experiences.values.first(where: { $0.title == "Roman Dinner Around Family Recipes" }),
              let blockedSlot = elenaExperience.slots.first(where: { $0.manualAvailability == .blockedByHost }) else {
            Issue.record("Expected a blocked seeded slot.")
            return
        }

        let draft = BookingRequestDraft(
            experienceID: elenaExperience.id,
            slotID: blockedSlot.id,
            seatsRequested: 1,
            introMessage: "Please reserve a seat.",
            guestNotes: ""
        )

        do {
            _ = try await store.submitRequest(draft: draft, guestID: seed.currentUserID)
            Issue.record("Expected blocked slot booking to fail.")
        } catch let error as MarketplaceError {
            #expect(error == .experienceUnavailable)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func cancellingAcceptedRequestReopensFullDate() async throws {
        let store = MockMarketplaceStore()
        let currentUser = try await store.currentUser()
        let hostRequests = try await store.hostRequests(hostID: currentUser.id)

        guard let requestToCancel = hostRequests.first(where: {
            $0.experienceTitle == "Kerala Lunch With Spice Stories"
            && $0.guestName == "Nora Chevalier"
            && $0.status == .accepted
        }) else {
            Issue.record("Expected a seeded accepted request that fills the date.")
            return
        }

        _ = try await store.updateRequestStatus(.cancelled, requestID: requestToCancel.id, actorID: currentUser.id)
        let refreshedExperiences = try await store.hostExperiences(hostID: currentUser.id)
        let updatedExperience = refreshedExperiences.first(where: { $0.id == requestToCancel.experienceID })
        let reopenedSlot = updatedExperience?.slots.first(where: { $0.id == requestToCancel.slotID })

        #expect(reopenedSlot?.remainingSeats == 1)
        #expect(updatedExperience?.nextStartAt == reopenedSlot?.startAt)
    }

    @Test
    func lockedDatesCannotBeBlockedByHost() async throws {
        let seed = MockMarketplaceStore.SeedData.mock()
        let store = MockMarketplaceStore(seed: seed)

        guard let hostExperience = seed.experiences.values.first(where: { $0.title == "Kerala Lunch With Spice Stories" }) else {
            Issue.record("Expected a host experience for the current user.")
            return
        }

        let lockedDay = DayKey(date: marketplaceCalendar.date(byAdding: .day, value: 5, to: .now) ?? .now)

        do {
            _ = try await store.updateBlockedDays(Set([lockedDay]), for: hostExperience.id, hostID: seed.currentUserID)
            Issue.record("Expected blocking a locked date to fail.")
        } catch let error as MarketplaceError {
            #expect(error == .busyDateCannotBeBlocked)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

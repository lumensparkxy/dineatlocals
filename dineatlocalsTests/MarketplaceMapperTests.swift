import Foundation
import Testing
@testable import dineatlocals

struct MarketplaceMapperTests {
    @Test
    func experienceRecordMapsIntoRangeBasedDomainModel() {
        let start = defaultExperienceRangeStart()
        let blockedDay = DayKey(date: marketplaceCalendar.date(byAdding: .day, value: 1, to: start) ?? start)

        let record = ExperienceRecord(
            id: UUID(),
            hostID: UUID(),
            hostName: "Elena Rossi",
            title: "Roman Dinner",
            mealTypeRawValue: "dinner",
            vibeRawValue: "storytelling",
            cuisineOrigin: "Roman Italian",
            description: "A family-style dinner.",
            city: "Zurich",
            neighborhood: "Seefeld",
            fullAddress: "Example Street 5",
            addressPrivacyRawValue: "neighborhoodOnly",
            maxSeats: 6,
            dietarySupportCSV: "Vegetarian, Gluten-aware",
            spokenLanguagesCSV: "Italian, English",
            publishStateRawValue: "published",
            availableFrom: start,
            availableUntil: marketplaceCalendar.date(byAdding: .day, value: 2, to: start) ?? start,
            serviceHour: 19,
            serviceMinute: 30,
            blockedDayKeysCSV: encodeDayKeyCSV([blockedDay])
        )

        let experience = MarketplaceMapper.makeExperience(from: record)

        #expect(experience.mealType == .dinner)
        #expect(experience.vibe == .storytelling)
        #expect(experience.dietarySupport == ["Vegetarian", "Gluten-aware"])
        #expect(experience.spokenLanguages == ["Italian", "English"])
        #expect(experience.photoAssetNames.count == 3)
        #expect(experience.slots.count == 3)
        #expect(experience.slots.allSatisfy { $0.seatCapacity == 6 })
        #expect(experience.slot(on: blockedDay)?.manualAvailability == .blockedByHost)
    }
}

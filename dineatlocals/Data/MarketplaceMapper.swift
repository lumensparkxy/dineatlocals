import Foundation

struct ExperienceRecord: Equatable, Sendable {
    var id: UUID
    var hostID: UUID
    var hostName: String
    var title: String
    var mealTypeRawValue: String
    var vibeRawValue: String
    var cuisineOrigin: String
    var description: String
    var city: String
    var neighborhood: String
    var fullAddress: String
    var addressPrivacyRawValue: String
    var maxSeats: Int
    var dietarySupportCSV: String
    var spokenLanguagesCSV: String
    var publishStateRawValue: String
    var availableFrom: Date
    var availableUntil: Date
    var serviceHour: Int
    var serviceMinute: Int
    var blockedDayKeysCSV: String = ""
    var photoAssetNamesCSV: String = ""
}

enum MarketplaceMapper {
    nonisolated static func makeExperience(from record: ExperienceRecord) -> Experience {
        let mealType = ExperienceMealType(rawValue: record.mealTypeRawValue) ?? .dinner
        let vibe = ExperienceVibe(rawValue: record.vibeRawValue) ?? .storytelling
        let addressPrivacy = AddressPrivacy(rawValue: record.addressPrivacyRawValue) ?? .neighborhoodOnly
        let publishState = ExperiencePublishState(rawValue: record.publishStateRawValue) ?? .draft
        let dietarySupport = splitCSV(record.dietarySupportCSV)
        let spokenLanguages = splitCSV(record.spokenLanguagesCSV)
        let photoAssetNames = splitCSV(record.photoAssetNamesCSV)
        let blockedDays = splitDayKeyCSV(record.blockedDayKeysCSV)
        let serviceTime = marketplaceCalendar.date(
            bySettingHour: record.serviceHour,
            minute: record.serviceMinute,
            second: 0,
            of: marketplaceCalendar.startOfDay(for: .now)
        ) ?? defaultExperienceServiceTime()

        return Experience(
            id: record.id,
            hostID: record.hostID,
            hostName: record.hostName,
            title: record.title,
            mealType: mealType,
            vibe: vibe,
            cuisineOrigin: record.cuisineOrigin,
            description: record.description,
            city: record.city,
            neighborhood: record.neighborhood,
            fullAddress: record.fullAddress,
            addressPrivacy: addressPrivacy,
            maxSeats: record.maxSeats,
            dietarySupport: dietarySupport,
            spokenLanguages: spokenLanguages,
            photoAssetNames: photoAssetNames.isEmpty
                ? ExperienceMediaCatalog.photoAssetNames(cuisineOrigin: record.cuisineOrigin, vibe: vibe, mealType: mealType)
                : photoAssetNames,
            publishState: publishState,
            slots: materializeSlots(
                availableFrom: record.availableFrom,
                availableUntil: record.availableUntil,
                serviceTime: serviceTime,
                seatCapacity: record.maxSeats,
                blockedDays: blockedDays
            )
        )
    }

    nonisolated static func splitCSV(_ value: String) -> [String] {
        parseCSVList(value)
    }
}

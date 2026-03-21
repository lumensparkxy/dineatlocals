import Foundation
import SwiftData

@Model
final class CachedExperienceRecord {
    var experienceID: UUID
    var title: String
    var city: String
    var mealTypeRawValue: String
    var cuisineOrigin: String
    var hostName: String
    var nextStartAt: Date
    var updatedAt: Date

    init(
        experienceID: UUID,
        title: String,
        city: String,
        mealTypeRawValue: String,
        cuisineOrigin: String,
        hostName: String,
        nextStartAt: Date,
        updatedAt: Date = .now
    ) {
        self.experienceID = experienceID
        self.title = title
        self.city = city
        self.mealTypeRawValue = mealTypeRawValue
        self.cuisineOrigin = cuisineOrigin
        self.hostName = hostName
        self.nextStartAt = nextStartAt
        self.updatedAt = updatedAt
    }

    convenience init(experience: Experience) {
        self.init(
            experienceID: experience.id,
            title: experience.title,
            city: experience.city,
            mealTypeRawValue: experience.mealType.rawValue,
            cuisineOrigin: experience.cuisineOrigin,
            hostName: experience.hostName,
            nextStartAt: experience.nextStartAt ?? .distantFuture
        )
    }
}

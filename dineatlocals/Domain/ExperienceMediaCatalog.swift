import Foundation

enum ExperienceMediaCatalog {
    nonisolated static func photoAssetNames(
        cuisineOrigin: String,
        vibe: ExperienceVibe,
        mealType: ExperienceMealType
    ) -> [String] {
        let spiceGallery = ["gallery-spice-01", "gallery-spice-02", "gallery-spice-03"]
        let hearthGallery = ["gallery-hearth-01", "gallery-hearth-02", "gallery-hearth-03"]
        let teaGallery = ["gallery-tea-01", "gallery-tea-02", "gallery-tea-03"]
        let lakeGallery = ["gallery-lake-01", "gallery-lake-02", "gallery-lake-03"]
        let cuisine = cuisineOrigin.lowercased()

        if cuisine.contains("indian") || cuisine.contains("levantine") || cuisine.contains("north african") {
            return spiceGallery
        }

        if cuisine.contains("japanese") || cuisine.contains("tea") {
            return teaGallery
        }

        if cuisine.contains("roman") || cuisine.contains("italian") {
            return hearthGallery
        }

        if cuisine.contains("vaud") || cuisine.contains("lake") || cuisine.contains("fish") {
            return lakeGallery
        }

        switch vibe {
        case .familyStyle:
            return mealType == .lunch ? lakeGallery : hearthGallery
        case .storytelling:
            return hearthGallery
        case .chefTable:
            return teaGallery
        case .festive:
            return spiceGallery
        }
    }
}

import XCTest

final class dineatlocalsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDiscoverFlowShowsExperienceCalendar() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Discover"].waitForExistence(timeout: 5))
        app.buttons["Roman Dinner Around Family Recipes"].tap()

        XCTAssertTrue(app.staticTexts["Around the table"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Request a seat"].exists)

        app.buttons["View all dates"].tap()
        XCTAssertTrue(app.otherElements["experience.detail.calendar"].exists)

        let selectableDate = app.buttons["experience.detail.calendar.day.\(dayIdentifier(daysFromToday: 2))"]
        XCTAssertTrue(selectableDate.waitForExistence(timeout: 5))
        selectableDate.tap()

        XCTAssertTrue(app.staticTexts["Time and place"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHostCanOpenCreateSheetAndPublishRangeExperience() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Host"].tap()
        XCTAssertTrue(app.buttons["Create Experience"].waitForExistence(timeout: 5))
        app.buttons["Create Experience"].tap()

        XCTAssertTrue(app.otherElements["host.create.calendar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["host.schedule.start"].exists)
        XCTAssertTrue(app.otherElements["host.schedule.end"].exists)
        XCTAssertTrue(app.otherElements["host.schedule.time"].exists)

        let titleField = app.textFields["host.experience.title"]
        titleField.tap()
        titleField.typeText("Range Test Dinner")

        let cuisineField = app.textFields["host.experience.cuisine"]
        cuisineField.tap()
        cuisineField.typeText("Coastal Indian")

        if app.textViews["host.experience.description"].exists {
            let descriptionField = app.textViews["host.experience.description"]
            descriptionField.tap()
            descriptionField.typeText("A warm dinner with a few blocked dates.")
        } else {
            let descriptionField = app.textFields["host.experience.description"]
            descriptionField.tap()
            descriptionField.typeText("A warm dinner with a few blocked dates.")
        }

        let addressField = app.textFields["host.experience.address"]
        addressField.tap()
        addressField.typeText("Testing Street 5")

        let blockedDate = app.buttons["host.create.calendar.day.\(dayIdentifier(daysFromToday: 2))"]
        XCTAssertTrue(blockedDate.waitForExistence(timeout: 5))
        blockedDate.tap()

        app.buttons["host.publishExperience"].tap()
        XCTAssertTrue(app.staticTexts["Range Test Dinner"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHostingAndRequestInboxAppear() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Host"].tap()
        XCTAssertTrue(app.buttons["Create Experience"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Kerala Lunch With Spice Stories"].exists)

        app.tabBars.buttons["Requests"].tap()
        app.buttons["requests.inbox.hosting"].tap()
        XCTAssertTrue(app.buttons["Accept"].waitForExistence(timeout: 5))
    }

    private func dayIdentifier(daysFromToday: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(byAdding: .day, value: daysFromToday, to: Date()) ?? Date()
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 1970, components.month ?? 1, components.day ?? 1)
    }
}

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
    func testGuestCanRequestSeatAndSeePendingRequest() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Discover"].waitForExistence(timeout: 5))
        app.buttons["Roman Dinner Around Family Recipes"].tap()

        XCTAssertTrue(app.staticTexts["Around the table"].waitForExistence(timeout: 5))
        app.buttons["View all dates"].tap()

        let selectedDate = app.buttons["experience.detail.calendar.day.\(dayIdentifier(daysFromToday: 3))"]
        XCTAssertTrue(selectedDate.waitForExistence(timeout: 5))
        selectedDate.tap()

        XCTAssertTrue(app.staticTexts["Time and place"].waitForExistence(timeout: 5))

        let requestButton = app.buttons["experience.detail.request"]
        XCTAssertTrue(requestButton.waitForExistence(timeout: 5))
        requestButton.tap()

        assertElementExists(app, identifier: "experience.request.sheet")

        assertElementExists(app, identifier: "experience.request.seats.stepper")
        let incrementSeatsButton = app.buttons["experience.request.seats.increment"]
        XCTAssertTrue(incrementSeatsButton.waitForExistence(timeout: 5))
        incrementSeatsButton.tap()
        XCTAssertTrue(app.staticTexts["Seats: 3"].waitForExistence(timeout: 3))

        let introMessage = "Excited to learn the story behind Roman Sunday sauces."
        let notes = "One vegetarian-friendly seat and step-free access if possible."

        enterText(introMessage, into: "experience.request.intro", in: app)
        let notesField = app.descendants(matching: .any)["experience.request.notes"]
        XCTAssertTrue(scrollUntilExists(notesField, in: app, scrollViewIdentifier: "experience.request.scroll"))
        enterText(notes, into: "experience.request.notes", in: app)
        dismissKeyboard(in: app)

        let submitButton = app.buttons["experience.request.submit"]
        XCTAssertTrue(scrollUntilExists(submitButton, in: app, scrollViewIdentifier: "experience.request.scroll"))
        submitButton.tap()

        XCTAssertTrue(app.tabBars.buttons["Requests"].waitForExistence(timeout: 5))
        let submittedIntro = app.staticTexts[introMessage]
        XCTAssertTrue(scrollUntilExists(submittedIntro, in: app, scrollViewIdentifier: "requests.scroll"))
        XCTAssertTrue(app.staticTexts["Pending"].exists)
        XCTAssertTrue(app.staticTexts["Host: Elena Rossi"].exists)
    }

    @MainActor
    func testHostCanOpenCreateSheetAndPublishRangeExperience() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Host"].tap()
        XCTAssertTrue(app.buttons["Create Experience"].waitForExistence(timeout: 5))
        app.buttons["Create Experience"].tap()

        XCTAssertTrue(app.otherElements["host.create.calendar"].waitForExistence(timeout: 5))
        assertElementExists(app, identifier: "host.schedule.start")
        assertElementExists(app, identifier: "host.schedule.end")
        assertElementExists(app, identifier: "host.schedule.time")

        let blockedDate = app.buttons["host.create.calendar.day.\(dayIdentifier(daysFromToday: 2))"]
        XCTAssertTrue(scrollUntilExists(blockedDate, in: app), "Blocked date should exist")
        blockedDate.tap()

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

    @MainActor
    private func assertElementExists(
        _ app: XCUIApplication,
        identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(identifier) should exist", file: file, line: line)
    }

    @MainActor
    private func scrollUntilExists(
        _ element: XCUIElement,
        in app: XCUIApplication,
        scrollViewIdentifier: String? = nil,
        attempts: Int = 10
    ) -> Bool {
        if element.waitForExistence(timeout: 1) {
            return true
        }

        let scrollView = scrollViewIdentifier.map { app.scrollViews[$0] } ?? app.scrollViews["host.create.scroll"]
        for _ in 0..<attempts {
            if scrollView.exists {
                scrollView.swipeUp()
            } else {
                app.swipeUp()
            }

            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

    @MainActor
    private func enterText(_ text: String, into identifier: String, in app: XCUIApplication) {
        if app.textFields[identifier].waitForExistence(timeout: 1) {
            app.textFields[identifier].tap()
            app.textFields[identifier].typeText(text)
            return
        }

        if app.textViews[identifier].waitForExistence(timeout: 1) {
            app.textViews[identifier].tap()
            app.textViews[identifier].typeText(text)
            return
        }

        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(identifier) should exist")
        element.tap()
        element.typeText(text)
    }

    @MainActor
    private func dismissKeyboard(in app: XCUIApplication) {
        guard app.keyboards.count > 0 else { return }

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }
}

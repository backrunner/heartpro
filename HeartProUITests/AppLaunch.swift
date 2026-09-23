import XCTest

extension XCUIApplication {
    /// Exercise the same notice acknowledgement as a user, without a launch bypass.
    @MainActor func launchHeartPro() {
        launch()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.buttons["acknowledgeUsageNotice"].exists || self.buttons["guideNext"].exists ||
            self.buttons["connectHealth"].exists || self.buttons["dailyOverview"].exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 30), .completed)
        if buttons["acknowledgeUsageNotice"].exists { buttons["acknowledgeUsageNotice"].tap() }
    }
}

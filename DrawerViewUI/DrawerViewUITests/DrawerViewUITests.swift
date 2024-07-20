//
//  DrawerViewUITests.swift
//  DrawerViewUITests
//
//  Created by Mikko Välimäki on 17.7.2024.
//

import XCTest

final class DrawerViewUITests: XCTestCase {

    var app: XCUIApplication!

    var reset: XCUIElement!

    var drawer: XCUIElement!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()

        reset = app.buttons["reset"]
        reset.tap()

        drawer = app.otherElements["drawer"]
        XCTAssertTrue(drawer.exists)
    }

    override func tearDownWithError() throws {
    }

    func testSwipeUp() throws {
        drawer.swipeUp()

        assertEvents(fromCells: app.cells, expectedEvents: [
            "willBeginDragging",
            "drawerDidMove",
            "willEndDragging",
            "willTransitionFrom",
            "drawerDidMove",
            "didTransitionTo",
        ])
    }

    func testSwipeUpDown() throws {
        drawer.swipeUp()
        drawer.swipeDown()

        assertEvents(fromCells: app.cells, expectedEvents: [
            // Up
            "willBeginDragging",
            "drawerDidMove",
            "willEndDragging",
            "willTransitionFrom",
            "drawerDidMove",
            "didTransitionTo",
            // Down
            "willBeginDragging",
            "drawerDidMove",
            "willEndDragging",
            "willTransitionFrom",
            "drawerDidMove",
            "didTransitionTo",
        ])
    }

    func testPresentation() throws {
        app.buttons["modal"].tap()

        assertEvents(fromCells: app.cells, expectedEvents: [
            "drawerPresentationWillBegin",
            "drawerPresentationDidEnd"
        ])
    }

    func testPresentationDismiss() throws {
        app.buttons["modal"].tap()
        app.otherElements["dismiss"].tap()

        assertEvents(fromCells: app.cells, expectedEvents: [
            "drawerPresentationWillBegin",
            "drawerPresentationDidEnd",
            "drawerDismissalWillBegin",
            "drawerDismissalDidEnd"
        ])
    }

    private func assertEvents(fromCells cells: XCUIElementQuery, expectedEvents: [String], file: StaticString = #filePath, line: UInt = #line) {
        let events = (0..<cells.count).map {
            cells.element(boundBy: $0).staticTexts.element.label
        }.joined(separator: "\n")
        let expected = expectedEvents.joined(separator: "\n")
        XCTAssertEqual(events, expected, file: file, line: line)
    }
}

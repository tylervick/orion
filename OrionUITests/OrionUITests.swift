//
//  OrionUITests.swift
//  OrionUITests
//
//  Created by Tyler Vick on 2/6/24.
//

import XCTest

extension XCUIElement {
    static var webWindow: XCUIElement {
        XCUIApplication().windows.element(matching: .identifier(equals: "webWindow"))
    }

    static var urlTextField: XCUIElement {
        XCUIApplication().textFields.element(matching: .label(equals: "URL Bar"))
    }

    static var manageExtensionsButton: XCUIElement {
        XCUIApplication().buttons.element(matching: .label(equals: "Manage Extensions"))
    }
}

extension NSPredicate {
    static func label(equals expectedLabel: String) -> NSPredicate {
        NSPredicate(format: "label = %@", expectedLabel)
    }

    static func identifier(equals expectedId: String) -> NSPredicate {
        NSPredicate(format: "identifier = %@", expectedId)
    }
}

final class OrionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testWindowIsDisplayed() throws {
        XCUIApplication().launch()
        XCTAssert(XCUIElement.webWindow.isHittable)
    }
    
    func testNavigateToValidURL() throws {
        XCUIApplication().launch()
        XCTAssert(XCUIElement.urlTextField.isHittable)
        XCUIElement.urlTextField.tap()
        XCUIElement.urlTextField.typeKey("a", modifierFlags: .command)
        XCUIElement.urlTextField.typeText("https://example.com\n")
    }
    
    func testOpenWebExtManage() throws {
        XCUIApplication().launch()
        XCTAssert(XCUIElement.manageExtensionsButton.isHittable)
        XCUIElement.manageExtensionsButton.click()
        XCTAssert(XCUIApplication().sheets.firstMatch.isHittable)
    }
}

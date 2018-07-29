//
//  DrawerPositionTests.swift
//  DrawerViewTests
//
//  Created by Mikko Välimäki on 2018-07-29.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import XCTest
import DrawerView

class DrawerPositionTests: XCTestCase {

    func testAdvance() {
        let positions: [DrawerPosition] = [.closed, .open]

        XCTAssertEqual(positions.advance(from: .closed, offset: 0), .closed)
        XCTAssertEqual(positions.advance(from: .closed, offset: 1), .open)
        XCTAssertEqual(positions.advance(from: .closed, offset: 2), nil)
        XCTAssertEqual(positions.advance(from: .open, offset: 1), nil)
        XCTAssertEqual(positions.advance(from: .open, offset: -1), .closed)
        XCTAssertEqual(positions.advance(from: .open, offset: -2), nil)
    }

    func testAdvanceWithEmpty() {
        let positions: [DrawerPosition] = []

        XCTAssertEqual(positions.advance(from: .open, offset: 1), nil)
        XCTAssertEqual(positions.advance(from: .open, offset: -1), nil)
        XCTAssertEqual(positions.advance(from: .closed, offset: 1), nil)
    }

    func testAdvanceWithNonexistent() {
        let positions: [DrawerPosition] = [.closed, .open, .partiallyOpen]

        XCTAssertEqual(positions.advance(from: .collapsed, offset: -1), nil)
        XCTAssertEqual(positions.advance(from: .collapsed, offset: 0), nil)
        XCTAssertEqual(positions.advance(from: .collapsed, offset: 1), nil)
    }
}

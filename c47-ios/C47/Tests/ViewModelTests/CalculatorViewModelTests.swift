// SPDX-License-Identifier: GPL-3.0-only
// CalculatorViewModelTests.swift
// C47 Calculator for iOS - ViewModel Unit Tests

import XCTest
@testable import C47

@MainActor
final class CalculatorViewModelTests: XCTestCase {
    var viewModel: CalculatorViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = CalculatorViewModel()
        viewModel.reset()
    }

    override func tearDown() async throws {
        viewModel.reset()
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.display, "0")
        XCTAssertEqual(viewModel.stackX, "0")
        XCTAssertEqual(viewModel.stackY, "0")
        XCTAssertEqual(viewModel.stackZ, "0")
        XCTAssertEqual(viewModel.stackT, "0")
        XCTAssertEqual(viewModel.angleMode, .degrees)
        XCTAssertFalse(viewModel.isShiftFActive)
        XCTAssertFalse(viewModel.isShiftGActive)
        XCTAssertFalse(viewModel.hasError)
    }

    // MARK: - Digit Entry Tests

    func testSingleDigitEntry() {
        viewModel.enterDigit(5)
        XCTAssertEqual(viewModel.display, "5")
    }

    func testMultiDigitEntry() {
        viewModel.enterDigit(1)
        viewModel.enterDigit(2)
        viewModel.enterDigit(3)
        XCTAssertEqual(viewModel.display, "123")
    }

    func testDecimalEntry() {
        viewModel.enterDigit(3)
        viewModel.enterDecimal()
        viewModel.enterDigit(1)
        viewModel.enterDigit(4)
        XCTAssertEqual(viewModel.display, "3.14")
    }

    func testChangeSign() {
        viewModel.enterDigit(5)
        viewModel.changeSign()
        XCTAssertEqual(viewModel.display, "-5")

        viewModel.changeSign()
        XCTAssertEqual(viewModel.display, "5")
    }

    // MARK: - Basic Operations Tests

    func testAddition() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.add()
        XCTAssertEqual(viewModel.display, "8")
    }

    func testSubtraction() {
        viewModel.enterDigit(1)
        viewModel.enterDigit(0)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.subtract()
        XCTAssertEqual(viewModel.display, "7")
    }

    func testMultiplication() {
        viewModel.enterDigit(6)
        viewModel.enter()
        viewModel.enterDigit(7)
        viewModel.multiply()
        XCTAssertEqual(viewModel.display, "42")
    }

    func testDivision() {
        viewModel.enterDigit(2)
        viewModel.enterDigit(0)
        viewModel.enter()
        viewModel.enterDigit(4)
        viewModel.divide()
        XCTAssertEqual(viewModel.display, "5")
    }

    // MARK: - Stack Operation Tests

    func testEnter() {
        viewModel.enterDigit(5)
        viewModel.enter()
        XCTAssertEqual(viewModel.stackX, "5")
        XCTAssertEqual(viewModel.stackY, "5")
    }

    func testSwap() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.swap()
        XCTAssertEqual(viewModel.stackX, "5")
        XCTAssertEqual(viewModel.stackY, "3")
    }

    func testRollDown() {
        viewModel.enterDigit(1)
        viewModel.enter()
        viewModel.enterDigit(2)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.enter()
        viewModel.enterDigit(4)
        viewModel.rollDown()
        XCTAssertEqual(viewModel.stackX, "3")
        XCTAssertEqual(viewModel.stackT, "4")
    }

    func testRecallLastX() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.add()
        viewModel.recallLastX()
        XCTAssertEqual(viewModel.display, "3")
    }

    func testClear() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.clear()
        XCTAssertEqual(viewModel.display, "0")
        XCTAssertEqual(viewModel.stackX, "0")
    }

    func testClearX() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.clearX()
        XCTAssertEqual(viewModel.display, "0")
        XCTAssertEqual(viewModel.stackY, "5")
    }

    // MARK: - Scientific Function Tests

    func testSquareRoot() {
        viewModel.enterDigit(9)
        viewModel.squareRoot()
        XCTAssertEqual(viewModel.display, "3")
    }

    func testSquare() {
        viewModel.enterDigit(5)
        viewModel.square()
        XCTAssertEqual(viewModel.display, "25")
    }

    func testReciprocal() {
        viewModel.enterDigit(4)
        viewModel.reciprocal()
        XCTAssertEqual(viewModel.display, "0.25")
    }

    func testPi() {
        viewModel.pi()
        XCTAssertTrue(viewModel.display.hasPrefix("3.14159"))
    }

    func testEulerE() {
        viewModel.eulerE()
        XCTAssertTrue(viewModel.display.hasPrefix("2.71828"))
    }

    // MARK: - Angle Mode Tests

    func testAngleModeDefault() {
        XCTAssertEqual(viewModel.angleMode, .degrees)
    }

    func testAngleModeCycle() {
        viewModel.cycleAngleMode()
        XCTAssertEqual(viewModel.angleMode, .radians)

        viewModel.cycleAngleMode()
        XCTAssertEqual(viewModel.angleMode, .gradians)

        viewModel.cycleAngleMode()
        XCTAssertEqual(viewModel.angleMode, .degrees)
    }

    func testSetAngleMode() {
        viewModel.setAngleMode(.radians)
        XCTAssertEqual(viewModel.angleMode, .radians)
    }

    // MARK: - Shift Key Tests

    func testShiftFToggle() {
        viewModel.toggleShiftF()
        XCTAssertTrue(viewModel.isShiftFActive)

        viewModel.toggleShiftF()
        XCTAssertFalse(viewModel.isShiftFActive)
    }

    func testShiftGToggle() {
        viewModel.toggleShiftG()
        XCTAssertTrue(viewModel.isShiftGActive)

        viewModel.toggleShiftG()
        XCTAssertFalse(viewModel.isShiftGActive)
    }

    func testShiftMutuallyExclusive() {
        viewModel.toggleShiftF()
        XCTAssertTrue(viewModel.isShiftFActive)
        XCTAssertFalse(viewModel.isShiftGActive)

        viewModel.toggleShiftG()
        XCTAssertFalse(viewModel.isShiftFActive)
        XCTAssertTrue(viewModel.isShiftGActive)
    }

    // MARK: - Error Handling Tests

    func testDivisionByZeroShowsError() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(0)
        viewModel.divide()
        XCTAssertTrue(viewModel.hasError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testErrorClearsOnNewEntry() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(0)
        viewModel.divide()
        XCTAssertTrue(viewModel.hasError)

        viewModel.enterDigit(1)
        XCTAssertFalse(viewModel.hasError)
    }

    // MARK: - Reset Tests

    func testReset() {
        viewModel.enterDigit(5)
        viewModel.enter()
        viewModel.enterDigit(3)
        viewModel.add()
        viewModel.setAngleMode(.radians)

        viewModel.reset()

        XCTAssertEqual(viewModel.display, "0")
        XCTAssertEqual(viewModel.stackX, "0")
        XCTAssertEqual(viewModel.angleMode, .degrees)
        XCTAssertFalse(viewModel.hasError)
    }
}

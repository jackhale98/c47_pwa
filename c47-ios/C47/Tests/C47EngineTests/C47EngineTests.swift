// SPDX-License-Identifier: GPL-3.0-only
// C47EngineTests.swift
// C47 Calculator for iOS - Engine Unit Tests

import XCTest
@testable import C47

final class C47EngineTests: XCTestCase {
    var engine: C47Engine!

    override func setUp() {
        super.setUp()
        engine = C47Engine.shared
        engine.reset()
    }

    override func tearDown() {
        engine.reset()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let state = engine.getState()
        XCTAssertEqual(state.display, "0")
        XCTAssertEqual(state.stackX, 0.0)
        XCTAssertEqual(state.stackY, 0.0)
        XCTAssertEqual(state.stackZ, 0.0)
        XCTAssertEqual(state.stackT, 0.0)
        XCTAssertFalse(state.hasError)
    }

    func testReset() {
        // Enter some values
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.plus)

        // Reset
        engine.reset()

        // Verify reset state
        let state = engine.getState()
        XCTAssertEqual(state.display, "0")
        XCTAssertEqual(state.stackX, 0.0)
    }

    // MARK: - Number Entry Tests

    func testDigitEntry() {
        engine.pressKey(.digit1)
        XCTAssertEqual(engine.getDisplay(), "1")

        engine.pressKey(.digit2)
        XCTAssertEqual(engine.getDisplay(), "12")

        engine.pressKey(.digit3)
        XCTAssertEqual(engine.getDisplay(), "123")
    }

    func testDecimalEntry() {
        engine.pressKey(.digit3)
        engine.pressKey(.dot)
        engine.pressKey(.digit1)
        engine.pressKey(.digit4)

        XCTAssertEqual(engine.getDisplay(), "3.14")
    }

    func testMultipleDecimalsIgnored() {
        engine.pressKey(.digit1)
        engine.pressKey(.dot)
        engine.pressKey(.digit5)
        engine.pressKey(.dot) // Should be ignored
        engine.pressKey(.digit9)

        XCTAssertEqual(engine.getDisplay(), "1.59")
    }

    func testChangeSign() {
        engine.pressKey(.digit5)
        engine.pressKey(.chs)
        XCTAssertEqual(engine.getDisplay(), "-5")

        engine.pressKey(.chs)
        XCTAssertEqual(engine.getDisplay(), "5")
    }

    func testExponentEntry() {
        engine.pressKey(.digit2)
        engine.pressKey(.dot)
        engine.pressKey(.digit5)
        engine.pressKey(.eex)
        engine.pressKey(.digit3)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 2500.0, accuracy: 0.001)
    }

    // MARK: - Basic Arithmetic Tests

    func testAddition() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.plus)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 8.0)
    }

    func testSubtraction() {
        engine.pressKey(.digit1)
        engine.pressKey(.digit0)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.minus)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 7.0)
    }

    func testMultiplication() {
        engine.pressKey(.digit6)
        engine.pressKey(.enter)
        engine.pressKey(.digit7)
        engine.pressKey(.multiply)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 42.0)
    }

    func testDivision() {
        engine.pressKey(.digit2)
        engine.pressKey(.digit0)
        engine.pressKey(.enter)
        engine.pressKey(.digit4)
        engine.pressKey(.divide)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 5.0)
    }

    func testDivisionByZero() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit0)
        engine.pressKey(.divide)

        let stack = engine.getStack()
        XCTAssertTrue(stack.x.isInfinite)
        XCTAssertTrue(engine.hasError)
    }

    // MARK: - Stack Operations Tests

    func testEnterDuplicatesX() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 5.0)
        XCTAssertEqual(stack.y, 5.0)
    }

    func testStackLift() {
        engine.pressKey(.digit1)
        engine.pressKey(.enter)
        engine.pressKey(.digit2)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.enter)
        engine.pressKey(.digit4)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 4.0)
        XCTAssertEqual(stack.y, 3.0)
        XCTAssertEqual(stack.z, 2.0)
        XCTAssertEqual(stack.t, 1.0)
    }

    func testStackDrop() {
        // Fill stack
        engine.pressKey(.digit1)
        engine.pressKey(.enter)
        engine.pressKey(.digit2)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.enter)
        engine.pressKey(.digit4)
        engine.pressKey(.enter)

        // Perform operation that drops stack
        engine.pressKey(.digit2)
        engine.pressKey(.plus)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 6.0) // 4 + 2
        XCTAssertEqual(stack.y, 3.0)
        XCTAssertEqual(stack.z, 2.0)
    }

    func testSwap() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.swap)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 5.0)
        XCTAssertEqual(stack.y, 3.0)
    }

    func testRollDown() {
        engine.pressKey(.digit1)
        engine.pressKey(.enter)
        engine.pressKey(.digit2)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.enter)
        engine.pressKey(.digit4)
        engine.pressKey(.rollDown)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 3.0)
        XCTAssertEqual(stack.y, 2.0)
        XCTAssertEqual(stack.z, 1.0)
        XCTAssertEqual(stack.t, 4.0)
    }

    func testLastX() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.plus)
        engine.pressKey(.lastX)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 3.0) // LastX was 3
        XCTAssertEqual(stack.y, 8.0) // Previous result
    }

    func testClearX() {
        engine.pressKey(.digit5)
        engine.pressKey(.enter)
        engine.pressKey(.digit3)
        engine.pressKey(.clx)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 0.0)
        XCTAssertEqual(stack.y, 5.0)
    }

    // MARK: - Scientific Functions Tests

    func testSquareRoot() {
        engine.pressKey(.digit9)
        engine.pressKey(.sqrt)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 3.0)
    }

    func testSquare() {
        engine.pressKey(.digit5)
        engine.pressKey(.square)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 25.0)
    }

    func testReciprocal() {
        engine.pressKey(.digit4)
        engine.pressKey(.reciprocal)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 0.25)
    }

    func testPower() {
        engine.pressKey(.digit2)
        engine.pressKey(.enter)
        engine.pressKey(.digit8)
        engine.pressKey(.power)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 256.0)
    }

    // MARK: - Trigonometric Tests

    func testSinDegrees() {
        engine.setAngleMode(.degrees)
        engine.pressKey(.digit3)
        engine.pressKey(.digit0)
        engine.pressKey(.sin)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 0.5, accuracy: 0.0001)
    }

    func testCosDegrees() {
        engine.setAngleMode(.degrees)
        engine.pressKey(.digit6)
        engine.pressKey(.digit0)
        engine.pressKey(.cos)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 0.5, accuracy: 0.0001)
    }

    func testTanDegrees() {
        engine.setAngleMode(.degrees)
        engine.pressKey(.digit4)
        engine.pressKey(.digit5)
        engine.pressKey(.tan)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 1.0, accuracy: 0.0001)
    }

    func testSinRadians() {
        engine.setAngleMode(.radians)
        // Enter pi/6 (0.5236...)
        engine.pressKey(.pi)
        engine.pressKey(.enter)
        engine.pressKey(.digit6)
        engine.pressKey(.divide)
        engine.pressKey(.sin)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 0.5, accuracy: 0.0001)
    }

    // MARK: - Logarithmic Tests

    func testNaturalLog() {
        engine.pressKey(.e)
        engine.pressKey(.ln)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 1.0, accuracy: 0.0001)
    }

    func testLog10() {
        engine.pressKey(.digit1)
        engine.pressKey(.digit0)
        engine.pressKey(.digit0)
        engine.pressKey(.log)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 2.0, accuracy: 0.0001)
    }

    func testExp() {
        engine.pressKey(.digit1)
        engine.pressKey(.exp)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, Double.pi.distance(to: 0) != 0 ? exp(1) : exp(1), accuracy: 0.0001)
    }

    func testPow10() {
        engine.pressKey(.digit3)
        engine.pressKey(.pow10)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 1000.0, accuracy: 0.0001)
    }

    // MARK: - Constants Tests

    func testPi() {
        engine.pressKey(.pi)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, Double.pi, accuracy: 0.0000001)
    }

    func testEulerE() {
        engine.pressKey(.e)

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, M_E, accuracy: 0.0000001)
    }

    // MARK: - Angle Mode Tests

    func testAngleModeChange() {
        XCTAssertEqual(engine.getAngleMode(), .degrees)

        engine.setAngleMode(.radians)
        XCTAssertEqual(engine.getAngleMode(), .radians)

        engine.setAngleMode(.gradians)
        XCTAssertEqual(engine.getAngleMode(), .gradians)

        engine.setAngleMode(.degrees)
        XCTAssertEqual(engine.getAngleMode(), .degrees)
    }

    func testAngleModeCycle() {
        XCTAssertEqual(engine.getAngleMode(), .degrees)

        engine.cycleAngleMode()
        XCTAssertEqual(engine.getAngleMode(), .radians)

        engine.cycleAngleMode()
        XCTAssertEqual(engine.getAngleMode(), .gradians)

        engine.cycleAngleMode()
        XCTAssertEqual(engine.getAngleMode(), .degrees)
    }

    // MARK: - State Persistence Tests

    func testStateSerialization() {
        // Set up some state
        engine.pressKey(.digit4)
        engine.pressKey(.digit2)
        engine.pressKey(.enter)
        engine.pressKey(.digit7)
        engine.setAngleMode(.radians)

        // Get state as data
        guard let data = engine.getStateData() else {
            XCTFail("Failed to get state data")
            return
        }

        XCTAssertGreaterThan(data.count, 0)

        // Reset
        engine.reset()
        XCTAssertEqual(engine.getStack().x, 0.0)

        // Restore state
        XCTAssertTrue(engine.setStateData(data))

        // Verify restored state
        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 7.0)
        XCTAssertEqual(stack.y, 42.0)
        XCTAssertEqual(engine.getAngleMode(), .radians)
    }

    // MARK: - Complex Calculation Tests

    func testQuadraticFormula() {
        // Solve x^2 - 5x + 6 = 0
        // x = (5 ± sqrt(25 - 24)) / 2
        // x = (5 ± 1) / 2 = 3 or 2

        // Calculate discriminant sqrt(b^2 - 4ac) where a=1, b=-5, c=6
        engine.pressKey(.digit5)
        engine.pressKey(.square)       // 25
        engine.pressKey(.enter)
        engine.pressKey(.digit4)
        engine.pressKey(.enter)
        engine.pressKey(.digit1)
        engine.pressKey(.multiply)     // 4
        engine.pressKey(.enter)
        engine.pressKey(.digit6)
        engine.pressKey(.multiply)     // 24
        engine.pressKey(.minus)        // 25 - 24 = 1
        engine.pressKey(.sqrt)         // 1

        // First root: (5 + 1) / 2
        engine.pressKey(.enter)
        engine.pressKey(.digit5)
        engine.pressKey(.plus)         // 6
        engine.pressKey(.enter)
        engine.pressKey(.digit2)
        engine.pressKey(.divide)       // 3

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 3.0, accuracy: 0.0001)
    }

    func testPythagoreanTheorem() {
        // c = sqrt(a^2 + b^2) for a=3, b=4 -> c=5
        engine.pressKey(.digit3)
        engine.pressKey(.square)       // 9
        engine.pressKey(.enter)
        engine.pressKey(.digit4)
        engine.pressKey(.square)       // 16
        engine.pressKey(.plus)         // 25
        engine.pressKey(.sqrt)         // 5

        let stack = engine.getStack()
        XCTAssertEqual(stack.x, 5.0, accuracy: 0.0001)
    }

    // MARK: - Error Handling Tests

    func testErrorClearing() {
        // Cause an error
        engine.pressKey(.digit1)
        engine.pressKey(.enter)
        engine.pressKey(.digit0)
        engine.pressKey(.divide)

        XCTAssertTrue(engine.hasError)

        // Clear error
        engine.clearError()
        XCTAssertFalse(engine.hasError)
    }

    func testNegativeSqrt() {
        engine.pressKey(.digit4)
        engine.pressKey(.chs)          // -4
        engine.pressKey(.sqrt)

        XCTAssertTrue(engine.hasError)
    }
}

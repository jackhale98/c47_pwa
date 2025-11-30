// SPDX-License-Identifier: GPL-3.0-only
// CalculatorState.swift
// C47 Calculator for iOS - Calculator State Model

import Foundation

/// Represents the complete state of the calculator
struct CalculatorState: Equatable, Codable {
    /// The current display string
    var display: String

    /// Stack register values
    var stackX: Double
    var stackY: Double
    var stackZ: Double
    var stackT: Double

    /// LastX register value
    var lastX: Double

    /// Current angle mode
    var angleMode: AngleMode

    /// Shift key states
    var isShiftFActive: Bool
    var isShiftGActive: Bool
    var isAlphaActive: Bool

    /// Error state
    var errorCode: Int
    var errorMessage: String?

    /// Default initial state
    static let initial = CalculatorState(
        display: "0",
        stackX: 0.0,
        stackY: 0.0,
        stackZ: 0.0,
        stackT: 0.0,
        lastX: 0.0,
        angleMode: .degrees,
        isShiftFActive: false,
        isShiftGActive: false,
        isAlphaActive: false,
        errorCode: 0,
        errorMessage: nil
    )

    /// Formatted stack values as strings
    var stackXString: String { formatValue(stackX) }
    var stackYString: String { formatValue(stackY) }
    var stackZString: String { formatValue(stackZ) }
    var stackTString: String { formatValue(stackT) }
    var lastXString: String { formatValue(lastX) }

    /// Whether there's an error
    var hasError: Bool { errorCode != 0 }

    /// Format a double value for display
    private func formatValue(_ value: Double) -> String {
        if value.isNaN {
            return "NaN"
        }
        if value.isInfinite {
            return value > 0 ? "∞" : "-∞"
        }
        if value == value.rounded() && abs(value) < 1e12 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.10g", value)
    }
}

// MARK: - Codable Conformance for AngleMode
extension AngleMode: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int32.self)
        self = AngleMode(rawValue: rawValue) ?? .degrees
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Stack Operations Helper
extension CalculatorState {
    /// Returns all stack values as an array [X, Y, Z, T]
    var stackArray: [Double] {
        [stackX, stackY, stackZ, stackT]
    }

    /// Returns all stack values as formatted strings
    var stackStrings: [String] {
        [stackXString, stackYString, stackZString, stackTString]
    }

    /// Update stack from an array [X, Y, Z, T]
    mutating func setStack(from array: [Double]) {
        guard array.count >= 4 else { return }
        stackX = array[0]
        stackY = array[1]
        stackZ = array[2]
        stackT = array[3]
    }
}
